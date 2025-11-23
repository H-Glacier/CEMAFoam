#!/bin/bash
# 验证设置脚本

echo "============================================="
echo "验证CEMAFoam设置"
echo "============================================="

echo ""
echo "1. 检查Make/files:"
echo "-------------------"
cat /workspace/src/thermophysicalModels/chemistryModel/Make/files
echo ""

echo "2. 检查pyjac_dummy.c是否存在:"
echo "------------------------------"
if [ -f /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/pyjac_dummy.c ]; then
    echo "✓ pyjac_dummy.c存在"
    echo "  文件大小: $(ls -lh /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/pyjac_dummy.c | awk '{print $5}')"
else
    echo "✗ pyjac_dummy.c不存在!"
fi
echo ""

echo "3. 检查eval_h函数定义:"
echo "----------------------"
grep -n "void eval_h" /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/pyjac_dummy.c
echo ""

echo "4. 检查头文件包含:"
echo "------------------"
grep "#include" /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/pyjac_dummy.c | head -5
echo ""

echo "5. 检查Make/options:"
echo "--------------------"
cat /workspace/src/thermophysicalModels/chemistryModel/Make/options
echo ""

echo "============================================="
echo "如果以上检查都正确，请执行："
echo "1. source你的OpenFOAM环境"
echo "2. cd /workspace/src/thermophysicalModels/chemistryModel"
echo "3. wclean"
echo "4. wmakeLnInclude ."
echo "5. wmake libso"
echo "============================================="