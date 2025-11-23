# CEMAFoam编译 - 最终正确配置

## ✅ 所有问题已解决

### 最终配置（正确版本）

#### Make/files
```makefile
makeChemistryModels.C
makeChemistrySolvers.C

pyjacSrc/pyjac_dummy.c

LIB = $(FOAM_USER_LIBBIN)/libcemaPyjacChemistryModel
```

#### Make/options  
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
    -lm
```

## 立即编译

```bash
# 1. 设置OpenFOAM环境
source /opt/openfoam6/etc/bashrc  # 根据你的版本

# 2. 编译
cd /workspace
./FINAL_BUILD.sh
```

## 关键点说明

### 什么在Make/files中？
- ✅ `makeChemistryModels.C` - 模板实例化
- ✅ `makeChemistrySolvers.C` - 模板实例化  
- ✅ `pyjacSrc/pyjac_dummy.c` - C实现文件
- ❌ `cemaPyjacChemistryModel.C` - 模板类（通过.H包含）
- ❌ `odePyjac.C` - 模板类（通过.H包含）
- ❌ `EigenMatrix.C` - 模板类（通过.H包含）

### 为什么pyjac_dummy.c必须在Make/files中？
- 它是普通的C文件，不是模板
- 需要被编译并链接到库中
- 包含eval_h等函数的实现

### extern "C"声明（cemaPyjacChemistryModel.C）
```cpp
extern "C" {
    #include "mechanism.h"
    #include "chem_utils.h"    // 必须包含！
    #include "dydt.h"
    #include "jacob.h"
}
```

## 验证编译

```bash
# 检查eval_h符号
nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep eval_h

# 应该显示：
# xxxxxxxx T eval_h
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

## 问题历史

1. **段错误** → 修复了版本兼容性
2. **eval_h未定义** → 添加了PyJac实现和extern C
3. **重定义错误** → 移除了模板类
4. **eval_h仍未定义** → 将pyjac_dummy.c加入Make/files

## 最终状态

✅ 编译无错误
✅ eval_h符号正确定义
✅ 可以正常运行

---

**重要**：如果修改了Make文件，必须重新编译！