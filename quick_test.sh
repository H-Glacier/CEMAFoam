#!/bin/bash
# 快速测试脚本

echo "快速测试CEMAFoam设置"
echo "===================="
echo ""

# 1. 检查文件
echo "1. 检查关键文件:"
echo -n "   pyjac_dummy.c: "
[ -f /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/pyjac_dummy.c ] && echo "✓" || echo "✗"

echo -n "   Make/files: "
[ -f /workspace/src/thermophysicalModels/chemistryModel/Make/files ] && echo "✓" || echo "✗"

echo -n "   Make/options: "
[ -f /workspace/src/thermophysicalModels/chemistryModel/Make/options ] && echo "✓" || echo "✗"

# 2. 检查Make/files内容
echo ""
echo "2. Make/files中是否包含pyjac_dummy.c:"
if grep -q "pyjac_dummy.c" /workspace/src/thermophysicalModels/chemistryModel/Make/files; then
    echo "   ✗ 错误: pyjac_dummy.c不应该在Make/files中"
else
    echo "   ✓ 正确: pyjac_dummy.c不在Make/files中"
fi

# 3. 检查Make/options内容
echo ""
echo "3. Make/options中是否包含pyjac_dummy.o:"
if grep -q "pyjac_dummy.o" /workspace/src/thermophysicalModels/chemistryModel/Make/options; then
    echo "   ✓ 正确: pyjac_dummy.o在Make/options中"
else
    echo "   ✗ 错误: pyjac_dummy.o应该在Make/options中"
fi

# 4. 检查extern C声明
echo ""
echo "4. cemaPyjacChemistryModel.C中的extern C声明:"
if grep -A3 "extern \"C\"" /workspace/src/thermophysicalModels/chemistryModel/chemistryModel/cemaPyjacChemistryModel/cemaPyjacChemistryModel.C | grep -q "chem_utils.h"; then
    echo "   ✓ 正确: extern C包含chem_utils.h"
else
    echo "   ✗ 错误: extern C未包含chem_utils.h"
fi

echo ""
echo "===================="
echo "如果以上检查都是✓，请运行:"
echo "./BUILD_WITH_PYJAC.sh"
echo "===================="