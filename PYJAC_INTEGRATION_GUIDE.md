# PyJac集成指南

## 问题描述
运行时出现符号未定义错误：
```
undefined symbol: eval_h
```

这是因为PyJac生成的C实现文件没有被编译和链接到库中。

## 解决方案

### 1. 生成PyJac化学动力学代码

你需要使用PyJac工具生成化学机理的C代码实现：

```bash
# 假设你有一个Cantera格式的机理文件 mech.yaml 或 mech.cti
pyjac -l c -i mech.yaml

# 这会生成以下文件：
# - chem_utils.c
# - dydt.c  
# - jacob.c
# - mass_mole.c
# - mechanism.c
# - rates.c
# - 其他相关的.c文件
```

### 2. 将PyJac生成的C文件添加到项目

将生成的C文件复制到PyJac源目录：
```bash
cp *.c /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/
```

如果pyjacSrc目录不存在，创建它：
```bash
mkdir -p /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/
```

### 3. 更新Make/files文件

编辑`/workspace/src/thermophysicalModels/chemistryModel/Make/files`，添加PyJac源文件：

```makefile
# 在现有文件列表后添加
pyjacSrc/chem_utils.c
pyjacSrc/dydt.c
pyjacSrc/jacob.c
pyjacSrc/mass_mole.c
pyjacSrc/mechanism.c
pyjacSrc/rates.c
# 添加其他生成的.c文件
```

### 4. 更新Make/options文件

编辑`/workspace/src/thermophysicalModels/chemistryModel/Make/options`：

```makefile
EXE_INC = \
    # ... 现有的include路径 ...
    -IpyjacInclude \
    -IpyjacSrc

LIB_LIBS = \
    # ... 现有的库 ...
    -lm  # 添加数学库
```

### 5. 重新编译

```bash
# 设置OpenFOAM环境
source /opt/OpenFOAM/OpenFOAM-v2006/etc/bashrc

# 清理并重新编译
cd /workspace/src/thermophysicalModels/chemistryModel
wclean
wmake libso
```

## 验证PyJac机理文件一致性

确保`pyjacInclude/mechanism.h`中的常量与你的化学机理匹配：

- `NSP` (53) - species数量
- `FWD_RATES` (325) - 正向反应数
- `REV_RATES` (309) - 可逆反应数
- `PRES_MOD_RATES` (41) - 压力相关反应数

## 临时解决方案（仅用于测试）

如果你暂时没有PyJac生成的文件，可以创建一个占位符实现：

创建文件`/workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/pyjac_dummy.c`：

```c
#include <string.h>
#include "header.h"

// 占位符实现 - 仅用于测试编译
void eval_h(const double T, double* h) {
    // 临时实现：返回零值
    for(int i = 0; i < 53; i++) {
        h[i] = 0.0;
    }
}

void eval_conc(const double T, const double P, 
               const double* Y, double* C, 
               double* RHO, double* RHOY, double* MW) {
    // 临时实现
}

void dydt(const double t, const double P, 
          const double* y, double* dy) {
    // 临时实现：返回零变化率
    for(int i = 0; i < 54; i++) {
        dy[i] = 0.0;
    }
}

void eval_jacob(const double t, const double P,
                const double* y, double* jac) {
    // 临时实现：返回单位矩阵
    memset(jac, 0, 54*54*sizeof(double));
    for(int i = 0; i < 54; i++) {
        jac[i*54 + i] = 1.0;
    }
}

// 添加CEMA相关函数
void cema(double* cem) {
    *cem = 0.0;
}
```

## 注意事项

1. **版本兼容性**：确保PyJac生成的代码与你的OpenFOAM版本兼容
2. **机理一致性**：PyJac生成的代码必须与你的化学机理文件一致
3. **性能优化**：PyJac可以生成优化的SIMD代码，考虑使用相应的编译器标志

## 常见问题

### Q: 编译时出现"undefined reference"错误
A: 确保所有PyJac生成的.c文件都添加到Make/files中

### Q: 运行时species数量不匹配
A: 检查mechanism.h中的NSP是否与thermophysicalProperties中的species列表一致

### Q: 反应数量显示错误
A: 代码已修复为使用PyJac的FWD_RATES常量（325个反应），而不是OpenFOAM的reactions_.size()

## 已完成的修复

1. ✅ 修复了OpenFOAM v6和v2006的版本兼容性问题
2. ✅ 修正了reactions数量识别（现在使用PyJac的FWD_RATES=325）
3. ✅ 添加了详细的诊断信息输出
4. ⏳ 需要集成PyJac生成的C代码以解决eval_h符号未定义问题