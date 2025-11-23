# CEMAFoam eval_h符号未定义问题 - 完整解决方案

## 问题分析
`eval_h`函数在第207行被调用但未定义，这是因为：
1. PyJac的C函数没有正确链接到C++代码
2. extern "C"声明不完整
3. 编译时PyJac实现没有被包含进库

## 已完成的修复

### 1. 修复extern "C"声明
**文件**: `cemaPyjacChemistryModel.C` (第39-45行)
```cpp
// Include PyJac headers with extern "C" for proper linking
extern "C" {
    #include "mechanism.h"
    #include "chem_utils.h"  // 包含eval_h声明
    #include "dydt.h"
    #include "jacob.h"
}
```

### 2. PyJac实现文件
**位置**: `/workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/pyjac_dummy.c`

这个文件提供了所有PyJac函数的实现：
- `eval_h` - 焓值计算
- `dydt` - 时间导数
- `eval_jacob` - 雅可比矩阵
- `cema` - 化学爆炸模式分析
- 其他辅助函数

### 3. 编译配置

#### Make/files
```makefile
makeChemistryModels.C
makeChemistrySolvers.C

chemistryModel/cemaPyjacChemistryModel/cemaPyjacChemistryModel.C
chemistryModel/cemaPyjacChemistryModel/EigenMatrix.C
chemistrySolver/odePyjac/odePyjac.C

LIB = $(FOAM_USER_LIBBIN)/libcemaPyjacChemistryModel
```

#### Make/options
```makefile
EXE_INC = \
    # ... OpenFOAM标准路径 ...
    -IpyjacInclude

LIB_LIBS = \
    # ... OpenFOAM标准库 ...
    pyjacSrc/pyjac_dummy.o \  # 直接链接PyJac对象文件
    -lm
```

## 编译步骤

### 自动编译（推荐）
```bash
# 1. 设置OpenFOAM环境
source /opt/openfoam6/etc/bashrc  # 或你的OpenFOAM路径

# 2. 运行编译脚本
cd /workspace
./BUILD_WITH_PYJAC.sh
```

### 手动编译
```bash
# 1. 设置OpenFOAM环境
source /opt/openfoam6/etc/bashrc

# 2. 进入编译目录
cd /workspace/src/thermophysicalModels/chemistryModel

# 3. 清理
wclean
rm -rf lnInclude
rm -f pyjacSrc/*.o

# 4. 编译PyJac实现
gcc -c -fPIC -IpyjacInclude pyjacSrc/pyjac_dummy.c -o pyjacSrc/pyjac_dummy.o

# 5. 创建lnInclude
wmakeLnInclude .

# 6. 编译OpenFOAM库
wmake libso

# 7. 验证符号
nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep eval_h
```

## 验证

编译成功后，应该看到：
```bash
$ nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep eval_h
0000xxxx T eval_h  # T表示符号已定义
```

## 在算例中使用

### 1. system/controlDict
```cpp
libs
(
    "libcemaPyjacChemistryModel.so"
);
```

### 2. constant/chemistryProperties
```cpp
chemistryType
{
    solver          odePyjac;
    method          cemaPyjac;
}
```

## 关键点总结

1. **extern "C"必须包含所有PyJac头文件** - 确保C函数正确链接到C++
2. **pyjac_dummy.o必须在Make/options中** - 直接链接对象文件
3. **不要将pyjac_dummy.c放在Make/files中** - 我们手动编译它

## 文件清单

- `/workspace/src/thermophysicalModels/chemistryModel/`
  - `pyjacSrc/pyjac_dummy.c` - PyJac实现
  - `pyjacInclude/*.h` - PyJac头文件
  - `Make/files` - 源文件列表
  - `Make/options` - 编译选项
  - `chemistryModel/cemaPyjacChemistryModel/cemaPyjacChemistryModel.C` - 主代码

## 故障排除

如果仍有问题：

1. **确认pyjac_dummy.o存在**:
   ```bash
   ls -la /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/pyjac_dummy.o
   ```

2. **检查编译日志**:
   ```bash
   wmake libso 2>&1 | grep pyjac
   ```

3. **验证所有符号**:
   ```bash
   nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep -E "eval_h|dydt|eval_jacob|cema"
   ```

## 生产环境

当前使用的是dummy实现。对于实际使用，需要：
1. 用PyJac生成真实的化学动力学代码
2. 替换pyjac_dummy.c
3. 重新编译