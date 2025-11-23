# 修复重定义错误

## 问题原因
编译错误显示：
```
error: redefinition of 'Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::cemaPyjacChemistryModel'
```

这是因为模板类被编译了两次：
1. 一次通过`Make/files`直接编译
2. 一次通过`.H`文件中的`#include "cemaPyjacChemistryModel.C"`包含

## 解决方案

### OpenFOAM模板类编译规则：
- 如果`.C`文件在`.H`文件中通过`#ifdef NoRepository`包含，就**不能**在`Make/files`中列出
- 模板实例化通过`makeChemistryModels.C`完成

### 修复后的Make/files：
```makefile
makeChemistryModels.C
makeChemistrySolvers.C

chemistryModel/cemaPyjacChemistryModel/EigenMatrix.C

LIB = $(FOAM_USER_LIBBIN)/libcemaPyjacChemistryModel
```

### 移除的文件：
- `chemistryModel/cemaPyjacChemistryModel/cemaPyjacChemistryModel.C` - 通过.H文件包含
- `chemistrySolver/odePyjac/odePyjac.C` - 通过.H文件包含

这两个文件都是模板类，已经在对应的.H文件末尾通过`#ifdef NoRepository`包含。

## 文件结构说明

```
cemaPyjacChemistryModel.H (第317-319行):
#ifdef NoRepository
    #include "cemaPyjacChemistryModel.C"  // 模板实现在这里包含
#endif

odePyjac.H (类似结构):
#ifdef NoRepository
    #include "odePyjac.C"  // 模板实现在这里包含
#endif
```

## 重要提示

- `EigenMatrix.C`保留在`Make/files`中，因为它不是模板类
- `makeChemistryModels.C`负责模板实例化
- `makeChemistrySolvers.C`负责求解器模板实例化