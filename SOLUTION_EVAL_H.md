# eval_h符号未定义问题 - 最终解决方案

## 问题分析
编译成功但运行时报错：`undefined symbol: eval_h`

这说明PyJac函数没有被正确链接到最终的库中。

## 解决方案

### 正确的配置

#### Make/files
```makefile
makeChemistryModels.C
makeChemistrySolvers.C

pyjacSrc/pyjac_dummy.c    # ← PyJac实现必须在这里

LIB = $(FOAM_USER_LIBBIN)/libcemaPyjacChemistryModel
```

**注意**：
- `pyjac_dummy.c`是C文件，不是模板，必须在`Make/files`中
- 模板类（.C文件）不能在这里

#### Make/options
```makefile
EXE_INC = \
    # ... OpenFOAM标准include路径 ...
    -IpyjacInclude    # PyJac头文件路径

LIB_LIBS = \
    # ... OpenFOAM标准库 ...
    -lm    # 数学库
```

**注意**：
- 不需要链接`pyjac_dummy.o`
- wmake会自动编译`Make/files`中的文件

### 文件结构

```
/workspace/src/thermophysicalModels/chemistryModel/
├── pyjacSrc/
│   └── pyjac_dummy.c           # C实现（包含eval_h等函数）
├── pyjacInclude/
│   ├── chem_utils.h           # eval_h函数声明
│   ├── mechanism.h            # 反应机理常量
│   └── ...
├── Make/
│   ├── files                  # 包含pyjac_dummy.c
│   └── options               # 不链接.o文件
└── chemistryModel/
    └── cemaPyjacChemistryModel/
        └── cemaPyjacChemistryModel.C  # 包含extern "C"声明
```

### cemaPyjacChemistryModel.C中的extern C
```cpp
// Include PyJac headers with extern "C" for proper linking
extern "C" {
    #include "mechanism.h"
    #include "chem_utils.h"    // 包含eval_h声明
    #include "dydt.h"
    #include "jacob.h"
}
```

## 编译步骤

```bash
# 1. 设置OpenFOAM环境
source /opt/openfoam6/etc/bashrc  # 根据你的版本

# 2. 运行最终编译脚本
cd /workspace
./FINAL_BUILD.sh
```

## 验证

编译后验证符号是否存在：
```bash
nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep eval_h
```

应该看到：
```
0000xxxx T eval_h    # T表示符号已定义
```

## 关键理解

### C文件 vs 模板类
- **C文件**（如`pyjac_dummy.c`）：必须在`Make/files`中
- **模板类**（如`cemaPyjacChemistryModel.C`）：不能在`Make/files`中

### extern "C"的重要性
- C函数必须用`extern "C"`包装才能在C++中正确链接
- 必须包含所有相关的头文件

## 常见错误

### 错误1：只链接.o文件
```makefile
# 错误做法
LIB_LIBS = \
    pyjacSrc/pyjac_dummy.o    # 这样可能找不到文件
```

### 错误2：忘记extern "C"
```cpp
// 错误做法
#include "chem_utils.h"    // 没有extern "C"包装
```

### 错误3：模板类和C文件混淆
```makefile
# 错误做法 - Make/files
cemaPyjacChemistryModel.C    # 模板类不应在这里
pyjac_dummy.c                 # C文件应该在这里
```

## 最终状态

✅ 配置正确：
- `pyjac_dummy.c`在`Make/files`中
- extern "C"包含所有PyJac头文件
- 模板类不在`Make/files`中
- `Make/options`不链接.o文件

现在重新编译应该可以解决eval_h未定义的问题。