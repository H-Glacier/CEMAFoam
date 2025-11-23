#!/bin/bash
# 测试PyJac编译的脚本

echo "================================================"
echo "   测试PyJac编译"
echo "================================================"
echo ""

cd /workspace/src/thermophysicalModels/chemistryModel

echo "1. 单独编译pyjac_dummy.c为对象文件："
echo "----------------------------------------"
gcc -c -fPIC -IpyjacInclude -o pyjac_test.o pyjacSrc/pyjac_dummy.c

if [ $? -eq 0 ]; then
    echo "✓ 编译成功"
    echo ""
    echo "2. 检查符号："
    echo "-------------"
    nm pyjac_test.o | grep -E "eval_h|dydt|eval_jacob|cema"
    echo ""
    
    echo "3. 创建独立的共享库："
    echo "---------------------"
    gcc -shared -o libpyjac_test.so pyjac_test.o -lm
    
    echo ""
    echo "4. 检查共享库中的符号："
    echo "----------------------"
    nm libpyjac_test.so | grep -E " T " | grep -E "eval_h|dydt|eval_jacob|cema"
    
    echo ""
    echo "5. 清理测试文件："
    rm -f pyjac_test.o libpyjac_test.so
    echo "✓ 清理完成"
else
    echo "✗ 编译失败"
    exit 1
fi

echo ""
echo "================================================"
echo "PyJac函数应该可以正常使用"
echo "================================================"