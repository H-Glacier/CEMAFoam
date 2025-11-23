#!/bin/bash
# 快速检查CEM值

echo "================================================"
echo "   CEM值快速检查"
echo "================================================"
echo ""

if [ -z "$1" ]; then
    echo "用法: ./check_cem.sh [时间目录]"
    echo "例如: ./check_cem.sh 0.001"
    exit 1
fi

TIME_DIR=$1

if [ ! -f "$TIME_DIR/cem" ]; then
    echo "错误: 找不到文件 $TIME_DIR/cem"
    exit 1
fi

echo "分析 $TIME_DIR/cem ..."
echo ""

# 提取CEM值（跳过头部）
cem_values=$(grep -E "^[-+]?[0-9]" $TIME_DIR/cem | grep -v "//" | head -100)

# 统计
echo "前10个CEM值："
echo "$cem_values" | head -10
echo ""

# 计算唯一值数量
unique_count=$(echo "$cem_values" | sort -u | wc -l)
total_count=$(echo "$cem_values" | wc -l)

echo "统计信息："
echo "  总数: $total_count"
echo "  唯一值数: $unique_count"
echo ""

if [ "$unique_count" -eq 1 ]; then
    echo "⚠️  警告: 所有CEM值都相同！"
    echo "   这表明使用了返回固定值的dummy实现"
    echo ""
    echo "   问题原因："
    echo "   pyjac_dummy.c中的cema函数返回固定值(1e-6)"
    echo ""
    echo "   解决方案："
    echo "   1. 运行: ./fix_cem_zero.sh"
    echo "   2. 选择选项1使用改进的dummy实现"
    echo "   3. 重新运行算例"
else
    echo "✓ CEM值有变化，计算正常"
    
    # 显示范围
    min_val=$(echo "$cem_values" | sort -g | head -1)
    max_val=$(echo "$cem_values" | sort -g | tail -1)
    echo "  最小值: $min_val"
    echo "  最大值: $max_val"
    
    # 检查符号
    pos_count=$(echo "$cem_values" | awk '$1 > 0' | wc -l)
    if [ "$pos_count" -gt 0 ]; then
        echo "  ⚠️ 发现 $pos_count 个正值（爆炸模式）"
    else
        echo "  ✓ 所有值为负（稳定）"
    fi
fi

# 同时检查温度
if [ -f "$TIME_DIR/T" ]; then
    echo ""
    echo "温度信息："
    T_values=$(grep -E "^[0-9]" $TIME_DIR/T | head -100)
    T_min=$(echo "$T_values" | sort -g | head -1)
    T_max=$(echo "$T_values" | sort -g | tail -1)
    echo "  温度范围: $T_min - $T_max K"
    
    if (( $(echo "$T_max < 1000" | bc -l) )); then
        echo "  提示: 温度较低，CEM应该为负值（稳定）"
    elif (( $(echo "$T_max > 1500" | bc -l) )); then
        echo "  提示: 温度较高，CEM可能为正值（爆炸）"
    fi
fi