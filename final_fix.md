# 最终修复说明

## 问题原因
`eval_h`符号未定义是因为PyJac函数实现没有被正确编译进库中。

## 已完成的修复

### 1. 直接编译PyJac函数
- `pyjac_dummy.c`现在直接包含在`Make/files`中
- 不再使用单独的PyJac库，直接编译进主库

### 2. 文件修改清单

#### Make/files
```
makeChemistryModels.C
makeChemistrySolvers.C

chemistryModel/cemaPyjacChemistryModel/cemaPyjacChemistryModel.C
chemistryModel/cemaPyjacChemistryModel/EigenMatrix.C
chemistrySolver/odePyjac/odePyjac.C

pyjacSrc/pyjac_dummy.c  # ← 直接编译进库

LIB = $(FOAM_USER_LIBBIN)/libcemaPyjacChemistryModel
```

#### Make/options
```makefile
EXE_INC = \
    # ... OpenFOAM标准包含路径 ...
    -IpyjacInclude  # PyJac头文件路径

LIB_LIBS = \
    # ... OpenFOAM标准库 ...
    -lm  # 数学库
```

## 立即编译

**重要**: 请按以下步骤操作

```bash
# 1. 设置OpenFOAM环境（选择你的版本）
source /opt/openfoam6/etc/bashrc
# 或
source /opt/OpenFOAM/OpenFOAM-v2006/etc/bashrc

# 2. 进入目录并清理
cd /workspace/src/thermophysicalModels/chemistryModel
wclean

# 3. 创建lnInclude
wmakeLnInclude .

# 4. 编译
wmake libso

# 5. 验证eval_h符号存在
nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep eval_h
```

## 验证符号

编译后运行以下命令验证：

```bash
# 检查eval_h符号
nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep -E "eval_h|eval_jacob|dydt"

# 应该看到类似输出：
# 0000xxxx T eval_h
# 0000xxxx T dydt
# 0000xxxx T eval_jacob
```

## 关键点

1. **pyjac_dummy.c必须在Make/files中** - 这样它会被编译进库
2. **不需要单独的PyJac库** - 所有函数直接编译进主库
3. **包含路径必须正确** - `-IpyjacInclude`确保找到头文件

## 如果仍有问题

如果`eval_h`仍然未定义，请检查：

1. **编译输出**：
   ```bash
   wmake libso 2>&1 | grep pyjac_dummy
   ```
   应该看到：`gcc ... pyjacSrc/pyjac_dummy.c`

2. **库文件更新时间**：
   ```bash
   ls -la $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so
   ```
   确保是刚刚编译的

3. **完整符号列表**：
   ```bash
   nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so > symbols.txt
   grep eval symbols.txt
   ```

## 最终结果

编译成功后，程序应该能够运行并显示：
- Species数量正确（53）
- OpenFOAM反应数（从文件读取）
- PyJac反应数（325）
- 成功调用eval_h函数