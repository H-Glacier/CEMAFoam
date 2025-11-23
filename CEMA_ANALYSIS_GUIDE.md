# CEMAFoam CEMA分析指南

## 什么是CEMA？

**CEMA (Chemical Explosive Mode Analysis)** 是一种分析燃烧化学动力学的方法，用于：
- 识别化学反应中的爆炸模式
- 确定主导化学时间尺度
- 分析自燃和火焰传播机制
- 识别关键反应路径

## CEMAFoam输出文件

### 1. 主要输出字段

运行CEMAFoam后，会在时间目录中生成以下场数据：

```
postProcessing/
├── 0/
├── 1e-06/
├── ...
└── endTime/
    ├── T                    # 温度场
    ├── p                    # 压力场
    ├── U                    # 速度场
    ├── Yi                   # 各组分质量分数（Y_H2, Y_O2等）
    ├── cem                  # Chemical Explosive Mode (关键!)
    ├── chemProdRate         # 化学生成率
    └── Qdot                 # 热释放率
```

### 2. cem场（最重要）

`cem`场包含每个网格单元的化学爆炸模式值：
- **正值**：表示存在爆炸模式（自燃倾向）
- **负值**：表示稳定模式
- **数值大小**：表示化学时间尺度的倒数

## 查看CEMA结果

### 1. 使用ParaView可视化

```bash
# 1. 创建.foam文件
touch case.foam

# 2. 打开ParaView
paraFoam

# 3. 在ParaView中：
#    - 加载cem场
#    - 设置合适的色标范围
#    - 创建等值面或切片
```

### 2. 使用foamToVTK转换

```bash
# 转换为VTK格式
foamToVTK -fields '(cem T p)'

# 查看VTK目录
ls VTK/
```

### 3. 提取cem数据

```bash
# 提取最后时刻的cem最大值
postProcess -func "max(cem)" -latestTime

# 提取沿线的cem分布
postProcess -func "lineAverage" -latestTime
```

## CEMA分析脚本

### 创建分析脚本 `analyzeCEMA.py`

```python
#!/usr/bin/env python3
import numpy as np
import matplotlib.pyplot as plt
from PyFoam.RunDictionary.ParsedParameterFile import ParsedParameterFile
import os

def read_openfoam_field(time_dir, field_name):
    """读取OpenFOAM场数据"""
    field_path = os.path.join(time_dir, field_name)
    
    with open(field_path, 'r') as f:
        lines = f.readlines()
    
    # 找到internalField部分
    start_idx = None
    for i, line in enumerate(lines):
        if 'internalField' in line:
            start_idx = i
            break
    
    # 提取数据
    data = []
    in_data = False
    for line in lines[start_idx:]:
        if '(' in line:
            in_data = True
            continue
        if ')' in line:
            break
        if in_data:
            try:
                data.append(float(line.strip()))
            except:
                pass
    
    return np.array(data)

def analyze_cem(case_dir):
    """分析CEM数据"""
    
    # 获取所有时间目录
    times = []
    for item in os.listdir(case_dir):
        try:
            time = float(item)
            times.append(time)
        except:
            pass
    
    times.sort()
    
    # 读取CEM数据
    cem_max = []
    cem_mean = []
    time_list = []
    
    for time in times:
        time_dir = os.path.join(case_dir, str(time))
        cem_file = os.path.join(time_dir, 'cem')
        
        if os.path.exists(cem_file):
            cem_data = read_openfoam_field(time_dir, 'cem')
            cem_max.append(np.max(cem_data))
            cem_mean.append(np.mean(cem_data))
            time_list.append(time)
            print(f"Time {time}: max CEM = {np.max(cem_data):.3e}, mean = {np.mean(cem_data):.3e}")
    
    # 绘图
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))
    
    ax1.plot(time_list, cem_max, 'r-', linewidth=2)
    ax1.set_xlabel('Time (s)')
    ax1.set_ylabel('Max CEM')
    ax1.set_title('Maximum Chemical Explosive Mode vs Time')
    ax1.grid(True)
    ax1.axhline(y=0, color='k', linestyle='--', alpha=0.3)
    
    ax2.plot(time_list, cem_mean, 'b-', linewidth=2)
    ax2.set_xlabel('Time (s)')
    ax2.set_ylabel('Mean CEM')
    ax2.set_title('Mean Chemical Explosive Mode vs Time')
    ax2.grid(True)
    ax2.axhline(y=0, color='k', linestyle='--', alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('cem_analysis.png', dpi=150)
    plt.show()
    
    # 识别自燃点
    if max(cem_max) > 0:
        ignition_time_idx = np.where(np.array(cem_max) > 0)[0][0]
        ignition_time = time_list[ignition_time_idx]
        print(f"\n自燃开始时间: {ignition_time} s")
        print(f"最大CEM值: {max(cem_max):.3e}")
    else:
        print("\n未检测到自燃（所有CEM值为负）")

if __name__ == "__main__":
    import sys
    case_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    analyze_cem(case_dir)
```

### 运行分析

```bash
# 使脚本可执行
chmod +x analyzeCEMA.py

# 运行分析
python3 analyzeCEMA.py /path/to/your/case
```

## 后处理工具

### 1. 创建CEM监控

在`system/controlDict`添加：

```cpp
functions
{
    cemMonitor
    {
        type            volFieldValue;
        libs            ("libfieldFunctionObjects.so");
        
        writeControl    timeStep;
        writeInterval   1;
        
        fields          (cem);
        
        regionType      all;
        operation       max;
        
        writeFields     false;
    }
    
    cemProbes
    {
        type            probes;
        libs            ("libsampling.so");
        
        writeControl    timeStep;
        writeInterval   1;
        
        fields          (cem T p);
        
        probeLocations
        (
            (0.5 0.5 0.5)    // 中心点
            (0.1 0.1 0.1)    // 其他监测点
        );
    }
}
```

### 2. 提取特征

```bash
# 提取最大CEM位置
postProcess -func 'minMaxComponents(cem)' -latestTime

# 计算CEM梯度
postProcess -func 'grad(cem)' -latestTime
```

## CEMA结果解释

### CEM值的物理意义

1. **CEM > 10^6 [1/s]**
   - 强爆炸模式
   - 快速自燃
   - 火焰前锋

2. **CEM ~ 10^4-10^6 [1/s]**
   - 中等反应速率
   - 预热区

3. **CEM ~ 0-10^4 [1/s]**
   - 慢反应
   - 接近稳定

4. **CEM < 0**
   - 稳定模式
   - 无自燃风险

### 典型CEMA分析结果

```
时间演化：
t=0s:     CEM < 0 (稳定)
t=0.001s: CEM ~ 10^3 (开始反应)
t=0.002s: CEM ~ 10^6 (自燃)
t=0.003s: CEM > 10^7 (爆炸传播)
```

## 高级分析

### 1. 组分贡献分析

```python
def analyze_species_contribution(case_dir, time):
    """分析各组分对CEM的贡献"""
    
    # 读取雅可比矩阵（如果输出）
    # 分析特征向量
    # 识别关键组分
    pass
```

### 2. 反应路径分析

```python
def reaction_path_analysis(case_dir, time):
    """分析主导反应路径"""
    
    # 读取反应速率
    # 构建反应网络
    # 识别关键路径
    pass
```

## 可视化建议

### ParaView设置

1. **CEM场可视化**
   - Color Map: Cool to Warm
   - Range: [-1e6, 1e7]
   - 使用log scale

2. **创建动画**
   - 时间序列动画
   - 追踪CEM峰值

3. **组合可视化**
   - CEM等值面 + 温度云图
   - 速度矢量 + CEM切片

## 输出文件总结

```
case/
├── system/
│   └── controlDict         # 控制输出
├── constant/
│   └── chemistryProperties # 化学设置
├── 0/                      # 初始条件
├── [时间步]/
│   ├── cem                 # 化学爆炸模式
│   ├── T                   # 温度
│   ├── p                   # 压力
│   ├── Y_*                 # 组分质量分数
│   └── chemProdRate        # 化学生成率
├── postProcessing/
│   ├── cemMonitor/         # CEM监控数据
│   └── cemProbes/          # 探针数据
└── log.reactingFoam        # 求解器日志
```

## 典型工作流程

1. **运行模拟**
   ```bash
   ./run_clean.sh
   ```

2. **监控收敛**
   ```bash
   tail -f postProcessing/cemMonitor/0/volFieldValue.dat
   ```

3. **可视化**
   ```bash
   paraFoam
   ```

4. **数据分析**
   ```bash
   python3 analyzeCEMA.py
   ```

5. **生成报告**
   - CEM时间演化图
   - 自燃延迟时间
   - 关键反应识别

## 论文图表建议

1. **CEM云图**：显示空间分布
2. **CEM-T散点图**：温度依赖性
3. **CEM时间曲线**：演化过程
4. **特征值谱**：模式分析

---

**注意**：CEMA分析的核心是`cem`场，它直接反映了化学系统的爆炸倾向性，是CEMAFoam的主要创新点。