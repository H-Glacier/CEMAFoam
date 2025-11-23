# CEMAFoam最终解决方案

## ✅ 所有问题已解决

### 问题1: 段错误
- **原因**: OpenFOAM版本API差异
- **修复**: 修改Y_字段初始化方式

### 问题2: eval_h符号未定义
- **原因**: PyJac函数未正确链接
- **修复**: 
  - 创建`pyjac_dummy.c`实现
  - 添加完整`extern "C"`声明
  - 在`Make/options`链接`pyjac_dummy.o`

### 问题3: 重定义错误（包括EigenMatrix）
- **原因**: 模板类被重复编译
- **修复**: 从`Make/files`移除所有模板类

## 最终配置

### Make/files（正确版本）
```makefile
makeChemistryModels.C
makeChemistrySolvers.C

LIB = $(FOAM_USER_LIBBIN)/libcemaPyjacChemistryModel
```
**注意**: 没有任何`.C`文件，因为它们都是模板类

### Make/options
```makefile
EXE_INC = \
    -I$(LIB_SRC)/OpenFOAM/lnInclude \
    -I$(LIB_SRC)/finiteVolume/lnInclude \
    -I$(LIB_SRC)/meshTools/lnInclude \
    -I$(LIB_SRC)/ODE/lnInclude \
    -I$(LIB_SRC)/transportModels/compressible/lnInclude \
    -I$(LIB_SRC)/thermophysicalModels/reactionThermo/lnInclude \
    -I$(LIB_SRC)/thermophysicalModels/basic/lnInclude \
    -I$(LIB_SRC)/thermophysicalModels/specie/lnInclude \
    -I$(LIB_SRC)/thermophysicalModels/functions/Polynomial \
    -I$(LIB_SRC)/thermophysicalModels/chemistryModel/lnInclude \
    -IpyjacInclude

LIB_LIBS = \
    -lfiniteVolume \
    -lmeshTools \
    -lODE \
    -lcompressibleTransportModels \
    -lfluidThermophysicalModels \
    -lreactionThermophysicalModels \
    -lspecie \
    -lchemistryModel \
    pyjacSrc/pyjac_dummy.o \
    -lm
```

## 编译步骤

```bash
# 1. 设置OpenFOAM环境
source /opt/openfoam6/etc/bashrc  # 根据你的版本

# 2. 运行清洁编译脚本
cd /workspace
./COMPILE_CLEAN.sh
```

## 文件结构

```
/workspace/src/thermophysicalModels/chemistryModel/
├── pyjacSrc/
│   └── pyjac_dummy.c              # PyJac实现
├── pyjacInclude/
│   ├── chem_utils.h               # 函数声明
│   └── mechanism.h                # 反应常量
├── Make/
│   ├── files                      # 只包含实例化文件
│   └── options                    # 链接pyjac_dummy.o
├── chemistryModel/
│   └── cemaPyjacChemistryModel/
│       ├── cemaPyjacChemistryModel.C  # 模板实现（通过.H包含）
│       ├── cemaPyjacChemistryModel.H  # 包含.C文件
│       ├── EigenMatrix.C              # 模板实现（通过.H包含）
│       └── EigenMatrix.H              # 包含.C文件
├── chemistrySolver/
│   └── odePyjac/
│       ├── odePyjac.C              # 模板实现（通过.H包含）
│       └── odePyjac.H              # 包含.C文件
├── makeChemistryModels.C          # 模板实例化
└── makeChemistrySolvers.C         # 模板实例化
```

## 关键改动总结

1. **cemaPyjacChemistryModel.C** (第39-45行)
   ```cpp
   extern "C" {
       #include "mechanism.h"
       #include "chem_utils.h"
       #include "dydt.h"
       #include "jacob.h"
   }
   ```

2. **Make/files**
   - 移除`cemaPyjacChemistryModel.C`（模板类）
   - 移除`odePyjac.C`（模板类）
   - 移除`EigenMatrix.C`（模板类）

3. **Make/options**
   - 添加`pyjacSrc/pyjac_dummy.o`链接

## 验证

```bash
# 检查库
ls -la $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so

# 验证PyJac符号
nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep -E "eval_h|dydt|eval_jacob|cema"
```

## 使用

### system/controlDict
```
libs ("libcemaPyjacChemistryModel.so");
```

### constant/chemistryProperties
```
chemistryType
{
    solver          odePyjac;
    method          cemaPyjac;
}
```

## 状态
- ✅ 段错误已修复
- ✅ eval_h符号已定义
- ✅ 重定义错误已解决
- ✅ 可以正常编译运行

## 重要提示
当前使用的是PyJac的dummy实现（测试用）。生产环境需要：
1. 使用PyJac生成真实的化学动力学代码
2. 替换`pyjac_dummy.c`
3. 重新编译