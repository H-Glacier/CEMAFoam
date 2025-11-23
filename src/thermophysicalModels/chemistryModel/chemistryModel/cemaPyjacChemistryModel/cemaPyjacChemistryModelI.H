/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     |
    \\  /    A nd           | www.openfoam.com
     \\/     M anipulation  |
-------------------------------------------------------------------------------
    Copyright (C) 2011-2017 OpenFOAM Foundation  -- Author: Mahmoud Gadalla
-------------------------------------------------------------------------------
License
    This file is part of CEMAFoam, derived from OpenFOAM.

    https://github.com/Aalto-CFD/CEMAFoam

    OpenFOAM is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    OpenFOAM is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with OpenFOAM.  If not, see <http://www.gnu.org/licenses/>.

\*---------------------------------------------------------------------------*/

#include "volFields.H"
#include "zeroGradientFvPatchFields.H"

// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //

template<class ReactionThermo, class ThermoType>
inline Foam::label
Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::nEqns() const
{
    // nEqns = number of species (N-1) + temperature + pressure
    return nSpecie_ + 1;
}


template<class ReactionThermo, class ThermoType>
inline Foam::PtrList<Foam::DimensionedField<Foam::scalar, Foam::volMesh>>&
Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::RR()
{
    return RR_;
}


template<class ReactionThermo, class ThermoType>
inline const Foam::volScalarField&
Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::yDefaultField() const
{
    if (!yDefaultFieldPtr_)
    {
        const fvMesh& mesh = this->mesh();

        if (!mesh.foundObject<volScalarField>("Ydefault"))
        {
            FatalErrorInFunction
                << "未找到 Ydefault 质量分数场，且某些物种缺少独立质量分数文件。"
                << "\n请确保在 0/ 目录下提供 Ydefault，或为所有物种创建单独的场。"
                << exit(FatalError);
        }

        yDefaultFieldPtr_ = &mesh.lookupObject<volScalarField>("Ydefault");
    }

    return *yDefaultFieldPtr_;
}


template<class ReactionThermo, class ThermoType>
inline const Foam::volScalarField&
Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::Yi
(
    const label i
) const
{
    const auto& composition = this->thermo().composition();
    const wordList& specieNames = composition.species();
    const fvMesh& mesh = this->mesh();

    if (i < 0 || i >= specieNames.size())
    {
        FatalErrorInFunction
            << "Requested specie index " << i
            << " is outside the available range [0," << specieNames.size()
            << "). 请检查 constant/thermophysicalProperties 中的物种定义。"
            << exit(FatalError);
    }

    const word& fieldName = specieNames[i];

    if (mesh.foundObject<volScalarField>(fieldName))
    {
        return mesh.lookupObject<volScalarField>(fieldName);
    }

    const volScalarField& fallback = this->yDefaultField();

    if (!fallbackLogged_.empty() && i < fallbackLogged_.size() && !fallbackLogged_[i])
    {
        Info<< "cemaPyjacChemistryModel: 物种 " << fieldName
            << " 未在 0/ 目录中提供独立质量分数场，改用 "
            << fallback.name() << "。" << endl;
        fallbackLogged_[i] = true;
    }

    return fallback;
}


template<class ReactionThermo, class ThermoType>
inline const Foam::PtrList<Foam::Reaction<ThermoType>>&
Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::reactions() const
{
    return reactions_;
}


template<class ReactionThermo, class ThermoType>
inline const Foam::PtrList<ThermoType>&
Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::specieThermo() const
{
    return specieThermo_;
}


template<class ReactionThermo, class ThermoType>
inline Foam::label
Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::nSpecie() const
{
    return nSpecie_;
}


template<class ReactionThermo, class ThermoType>
inline Foam::label
Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::nReaction() const
{
    return nReaction_;
}


template<class ReactionThermo, class ThermoType>
inline Foam::scalar
Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::Treact() const
{
    return Treact_;
}


template<class ReactionThermo, class ThermoType>
inline Foam::scalar&
Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::Treact()
{
    return Treact_;
}


template<class ReactionThermo, class ThermoType>
inline const Foam::DimensionedField<Foam::scalar, Foam::volMesh>&
Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::RR
(
    const label i
) const
{
    return RR_[i];
}

template<class ReactionThermo, class ThermoType>
Foam::DimensionedField<Foam::scalar, Foam::volMesh>&
Foam::cemaPyjacChemistryModel<ReactionThermo, ThermoType>::RR
(
    const label i
)
{
    return RR_[i];
}


// ************************************************************************* //
