# CEMA分析快速指南

## 🎯 核心输出：cem场

CEMAFoam最重要的输出是**cem场**（Chemical Explosive Mode），它表示每个网格点的化学爆炸倾向性。

## 📁 输出文件位置

运行后，在你的算例目录会生成：

```
your_case/
├── 0.001/
│   ├── cem          # ← 这是CEMA值！
│   ├── T            # 温度
│   ├── p            # 压力
│   └── Y_*          # 各组分浓度
├── 0.002/
│   └── cem          # 每个时间步都有
└── ...
```

## 🔍 快速查看结果

### 1. 查看最大CEM值
```bash
# 查看最新时刻的cem最大值
tail -n 50 [最新时间目录]/cem | grep -E "[0-9]" | sort -g | tail -1
```

### 2. 使用ParaView可视化
```bash
# 创建foam文件
touch case.foam

# 启动ParaView
paraFoam

# 在ParaView中：
# 1. 选择cem场
# 2. Apply
# 3. 调整色标查看分布
```

### 3. 快速Python分析
```python
#!/usr/bin/env python3
import numpy as np

def quick_cem_check(time_dir):
    """快速检查CEM值"""
    with open(f"{time_dir}/cem", 'r') as f:
        lines = f.readlines()
    
    # 提取数值
    values = []
    in_data = False
    for line in lines:
        if '(' in line:
            in_data = True
        elif ')' in line:
            break
        elif in_data:
            try:
                values.append(float(line.strip()))
            except:
                pass
    
    values = np.array(values)
    print(f"CEM统计:")
    print(f"  最大值: {np.max(values):.2e}")
    print(f"  最小值: {np.min(values):.2e}")
    print(f"  平均值: {np.mean(values):.2e}")
    print(f"  正值数: {np.sum(values > 0)}/{len(values)}")
    
    if np.max(values) > 0:
        print("  ⚠️ 检测到爆炸模式（CEM > 0）!")
    else:
        print("  ✓ 系统稳定（所有CEM < 0）")

# 使用
quick_cem_check("0.001")
```

## 📊 CEM值含义

| CEM值范围 | 物理意义 | 状态 |
|----------|---------|------|
| > 10^7 | 极快反应 | 🔥 爆燃/爆轰 |
| 10^5 ~ 10^7 | 快速反应 | 🔥 自燃 |
| 0 ~ 10^5 | 慢反应 | ⚡ 预热 |
| < 0 | 稳定 | ✅ 无自燃 |

## 📈 监控CEM演化

在`system/controlDict`添加：

```cpp
functions
{
    maxCEM
    {
        type            volFieldValue;
        libs            ("libfieldFunctionObjects.so");
        
        writeControl    timeStep;
        writeInterval   1;
        
        fields          (cem);
        regionType      all;
        operation       max;
    }
}
```

运行后查看：
```bash
cat postProcessing/maxCEM/0/volFieldValue.dat
```

## 🚀 完整分析流程

### 步骤1：运行模拟
```bash
reactingFoam | tee log.foam
```

### 步骤2：检查CEM输出
```bash
# 列出所有时间目录
ls -d [0-9]* | sort -g

# 查看最后时刻的CEM
cd $(ls -d [0-9]* | sort -g | tail -1)
head -100 cem
```

### 步骤3：可视化
```bash
paraFoam
# 或
foamToVTK -fields '(cem T)'
```

### 步骤4：绘制CEM时间曲线
```python
import matplotlib.pyplot as plt
import glob

times = []
max_cems = []

for time_dir in sorted(glob.glob("[0-9]*")):
    # 读取并分析每个时间步的cem
    pass

plt.plot(times, max_cems)
plt.xlabel('Time (s)')
plt.ylabel('Max CEM (1/s)')
plt.show()
```

## 💡 CEMA分析的价值

1. **预测自燃**：CEM > 0 表示可能自燃
2. **识别热点**：找到反应最剧烈的区域
3. **优化设计**：避免爆炸风险区域
4. **理解机理**：分析化学动力学主导模式

## 📝 典型输出示例

```
Time = 0.001
  CEM range: [-1e5, -100]  → 稳定

Time = 0.002  
  CEM range: [-1e4, 1e3]   → 开始反应

Time = 0.003
  CEM range: [-1e3, 1e6]   → 自燃！

Time = 0.004
  CEM range: [1e5, 1e8]    → 火焰传播
```

## ✅ 成功标志

如果你看到：
- ✓ 生成了cem文件
- ✓ CEM值在合理范围内
- ✓ 可以在ParaView中可视化
- ✓ 物理趋势合理

那么CEMA分析就成功了！

## 🆘 常见问题

**Q: cem文件很大怎么办？**
A: 使用二进制格式，在controlDict设置：
```cpp
writeFormat binary;
```

**Q: CEM一直是负值？**
A: 系统稳定，没有自燃。可以提高初始温度。

**Q: CEM值异常大？**
A: 检查化学机理和初始条件是否合理。

---

**记住**：`cem`场是CEMAFoam的核心创新，它量化了化学系统的爆炸倾向性！