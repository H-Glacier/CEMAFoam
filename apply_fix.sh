#!/bin/bash

echo "=================================="
echo "应用 PyJac 段错误修复"
echo "=================================="

# 备份原始文件
if [ -f /workspace/tutorials/premixedFlame1D/constant/thermophysicalProperties ]; then
    echo "备份原始 thermophysicalProperties 文件..."
    cp /workspace/tutorials/premixedFlame1D/constant/thermophysicalProperties \
       /workspace/tutorials/premixedFlame1D/constant/thermophysicalProperties.backup
fi

# 应用修复
echo "应用修复的配置文件..."
cat > /workspace/tutorials/premixedFlame1D/constant/thermophysicalProperties << 'EOF'
/*--------------------------------*- C++ -*----------------------------------*\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |
|  \\    /   O peration     | Version:  v2006                                 |
|   \\  /    A nd           | Website:  www.openfoam.com                      |
|    \\/     M anipulation  |                                                 |
\*---------------------------------------------------------------------------*/
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    location    "constant";
    object      thermophysicalProperties;
}
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

thermoType
{
    type            hePsiThermo;
    mixture         reactingMixture;
    transport       const;  // 修改为 const 以避免 Dimix 错误
    thermo          janaf;
    energy          sensibleEnthalpy;
    equationOfState perfectGas;
    specie          specie;
}

inertSpecie N2;

chemistryReader foamChemistryReader;
foamChemistryFile "<constant>/reactionsGRIPyjac";
foamChemistryThermoFile "<constant>/thermo.compressibleGasGRI";

// ************************************************************************* //
EOF

echo "修复已应用！"
echo ""
echo "=================================="
echo "下一步操作："
echo "=================================="
echo ""
echo "1. 编译修改后的库（如果修改了源代码）："
echo "   cd /workspace/src/thermophysicalModels/chemistryModel"
echo "   wmake libso"
echo ""
echo "2. 运行测试："
echo "   cd /workspace/tutorials/premixedFlame1D"
echo "   blockMesh"
echo "   [你的求解器名称]"
echo ""
echo "3. 如果仍有问题，运行诊断："
echo "   python3 /workspace/diagnose_pyjac.py"
echo ""
echo "4. 恢复原始配置："
echo "   cp /workspace/tutorials/premixedFlame1D/constant/thermophysicalProperties.backup \\"
echo "      /workspace/tutorials/premixedFlame1D/constant/thermophysicalProperties"
echo ""
echo "=================================="