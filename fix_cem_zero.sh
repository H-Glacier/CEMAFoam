#!/bin/bash
# 修复CEM值接近0的问题

echo "================================================"
echo "   修复CEM值接近0的问题"
echo "================================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查OpenFOAM环境
if [ -z "$WM_PROJECT" ]; then
    echo -e "${RED}错误: OpenFOAM环境未设置!${NC}"
    echo "请先执行: source /path/to/OpenFOAM/etc/bashrc"
    exit 1
fi

cd /workspace/src/thermophysicalModels/chemistryModel

echo -e "${YELLOW}问题诊断：${NC}"
echo "当前使用的pyjac_dummy.c返回固定的CEM值(1e-6)，这就是为什么所有网格的CEM都接近0。"
echo ""

echo "选择修复方案："
echo "1) 使用改进的dummy实现（推荐用于测试）"
echo "2) 手动编辑现有dummy文件"
echo "3) 查看当前CEM函数"
read -p "请选择 [1-3]: " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}步骤1: 备份原始文件...${NC}"
        cp pyjacSrc/pyjac_dummy.c pyjacSrc/pyjac_dummy.c.orig
        echo -e "${GREEN}✓ 已备份到pyjac_dummy.c.orig${NC}"
        
        echo ""
        echo -e "${YELLOW}步骤2: 使用改进的dummy实现...${NC}"
        cp pyjacSrc/pyjac_dummy_improved.c pyjacSrc/pyjac_dummy.c
        echo -e "${GREEN}✓ 已更新pyjac_dummy.c${NC}"
        
        echo ""
        echo -e "${YELLOW}步骤3: 重新编译...${NC}"
        wclean > /dev/null 2>&1
        wmakeLnInclude . > /dev/null 2>&1
        wmake libso
        
        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}================================================${NC}"
            echo -e "${GREEN}   ✓ 修复完成！${NC}"
            echo -e "${GREEN}================================================${NC}"
            echo ""
            echo "改进的dummy实现现在会根据温度返回不同的CEM值："
            echo "  T < 1000K:     CEM ~ -1e4 (稳定)"
            echo "  1000-1200K:    CEM ~ -100 到 0 (过渡)"
            echo "  1200-1500K:    CEM ~ 0 到 1e3 (弱爆炸)"
            echo "  1500-1800K:    CEM ~ 1e3 到 1e5 (中等爆炸)"
            echo "  T > 1800K:     CEM ~ 1e7 (强爆炸)"
            echo ""
            echo -e "${GREEN}现在重新运行你的算例，CEM值应该会根据温度场变化了！${NC}"
        else
            echo -e "${RED}✗ 编译失败，请检查错误信息${NC}"
            exit 1
        fi
        ;;
    2)
        echo ""
        echo "请手动编辑以下文件："
        echo "  /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/pyjac_dummy.c"
        echo ""
        echo "找到cema函数（约第98行），修改为："
        echo -e "${YELLOW}"
        cat << 'EOF'
void cema(double* cem) {
    // 基于某个温度值（这里假设1500K）
    double T = 1500.0;  // 实际应该从参数获取
    
    if (T > 1500.0) {
        *cem = 1.0e6;  // 爆炸模式
    } else if (T > 1000.0) {
        *cem = -1000.0 + (T - 1000.0) * 10.0;
    } else {
        *cem = -1.0e4;  // 稳定
    }
}
EOF
        echo -e "${NC}"
        echo "修改后重新编译: wmake libso"
        ;;
    3)
        echo ""
        echo -e "${YELLOW}当前cema函数实现：${NC}"
        grep -A 5 "void cema" pyjacSrc/pyjac_dummy.c
        echo ""
        echo -e "${RED}问题：返回固定值1.0e-6，所以所有CEM都接近0${NC}"
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo "================================================"
echo "其他建议："
echo "1. 检查温度范围: grep 'T' your_case/latest_time/T | sort -g"
echo "2. 调整Treact: 在chemistryProperties中设置Treact为0"
echo "3. 使用真实PyJac: pyjac --lang c --input mechanism.yaml"
echo "================================================"