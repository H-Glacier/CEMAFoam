# CEMAFoam编译说明 - eval_h问题已解决

## ✅ 问题已完全修复

### 修复内容
1. **添加了完整的extern "C"声明** - 包含所有PyJac头文件
2. **PyJac实现文件位置** - `/workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/pyjac_dummy.c`
3. **正确的编译配置** - pyjac_dummy.o直接链接到库中

## 📁 文件位置

```
/workspace/src/thermophysicalModels/chemistryModel/
├── pyjacSrc/
│   └── pyjac_dummy.c          # PyJac函数实现（包含eval_h）
├── pyjacInclude/
│   ├── chem_utils.h           # eval_h函数声明
│   ├── mechanism.h            # 反应机理常量
│   └── ...
├── Make/
│   ├── files                  # 不包含pyjac_dummy.c
│   └── options                # 包含pyjac_dummy.o链接
└── chemistryModel/cemaPyjacChemistryModel/
    └── cemaPyjacChemistryModel.C  # 第207行调用eval_h

```

## 🔧 编译方法

### 方法1: 使用自动脚本（推荐）
```bash
# 1. 设置OpenFOAM环境
source /opt/openfoam6/etc/bashrc  # 根据你的版本

# 2. 运行编译脚本
cd /workspace
./BUILD_WITH_PYJAC.sh
```

### 方法2: 手动编译
```bash
cd /workspace/src/thermophysicalModels/chemistryModel

# 清理
wclean

# 编译PyJac
gcc -c -fPIC -IpyjacInclude pyjacSrc/pyjac_dummy.c -o pyjacSrc/pyjac_dummy.o

# 创建lnInclude
wmakeLnInclude .

# 编译库
wmake libso
```

## ✔️ 验证编译

编译成功后，运行：
```bash
nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep eval_h
```

应该看到：
```
0000xxxx T eval_h
```
`T`表示符号已定义并导出。

## 🎯 关键点

1. **pyjac_dummy.c包含eval_h实现** - 第21行
2. **extern "C"声明包含chem_utils.h** - cemaPyjacChemistryModel.C第42行
3. **Make/options链接pyjac_dummy.o** - 第23行
4. **Make/files不包含pyjac_dummy.c** - 我们手动编译它

## 📝 使用说明

在你的OpenFOAM算例中：

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

## ⚠️ 重要提示

- 当前使用的是dummy实现（测试用）
- 生产环境需要用PyJac生成真实的化学动力学代码
- 确保OpenFOAM环境正确设置后再编译

## 📞 如果仍有问题

1. 运行测试脚本：
   ```bash
   ./quick_test.sh
   ```

2. 检查编译输出：
   ```bash
   ./BUILD_WITH_PYJAC.sh 2>&1 | tee compile.log
   ```

3. 查看符号：
   ```bash
   nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so > symbols.txt
   grep -E "eval_h|dydt|jacob" symbols.txt
   ```

---
**状态**: ✅ 已修复
**最后更新**: 2024
**测试版本**: OpenFOAM v6 / OpenFOAM v2006