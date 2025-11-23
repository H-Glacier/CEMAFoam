#!/bin/bash
# 验证当前配置

echo "================================================"
echo "   验证CEMAFoam配置"
echo "================================================"
echo ""

echo "1. Make/files内容："
echo "-------------------"
cat /workspace/src/thermophysicalModels/chemistryModel/Make/files
echo ""

echo "2. Make/options内容："
echo "--------------------"
cat /workspace/src/thermophysicalModels/chemistryModel/Make/options
echo ""

echo "3. pyjac_dummy.c是否存在："
echo "-------------------------"
if [ -f /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/pyjac_dummy.c ]; then
    echo "✓ 文件存在"
    echo "  检查eval_h定义："
    grep -n "^void eval_h" /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/pyjac_dummy.c
else
    echo "✗ 文件不存在"
fi
echo ""

echo "4. extern C声明检查："
echo "--------------------"
echo "cemaPyjacChemistryModel.C中的extern C块："
grep -A 5 'extern "C"' /workspace/src/thermophysicalModels/chemistryModel/chemistryModel/cemaPyjacChemistryModel/cemaPyjacChemistryModel.C
echo ""

echo "================================================"
echo "配置总结："
echo "- pyjac_dummy.c应该在Make/files中"
echo "- 不需要在Make/options中链接.o文件"
echo "- 模板类不应在Make/files中"
echo "================================================"