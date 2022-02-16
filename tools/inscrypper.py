import os
import json
from re import S
import shutil
import textwrap

basePath = "/media/107zxz/Extra Files/Games/InscrExt/globalgamemanagers/Assets/Resources/data/"
sigilPaths = ["abilities/part1/", "abilities/gbc/", "abilities/part3/"]
cardPaths = ["cards/nature/", "cards/technology/", "cards/undead/", "cards/wizard/"]

initialDir = os.getcwd()
os.chdir(basePath)

# Analyse sigils
ref_sigils = {}

for sPath in sigilPaths:
    print("Grabbing sigils from", sPath)

    # Iterate all asset files
    for sigilFile in os.listdir(sPath):
        # Am I an actual asset file?
        if ".meta" not in sigilFile:
            with open(sPath + sigilFile) as sfHandle:
                
                # Remember sigil code, as it is found in file first
                sCode = -1
                sDesc = ""
                sFileName = ""
                sName = ""

                for line in sfHandle.readlines():
                    # Grab sigil image
                    if line.startswith("  m_Name"):
                        tName = line.split(": ")[1].strip().lower()

                        # Active ability naming discrepancy
                        tName = tName.replace("activated", "activated_")

                        sFileName = "pixelability_" + tName + ".png"
                    if line.startswith("  ability: "):
                        sCode = line.split(": ")[1].strip()
                    if line.startswith("  rulebookName: "):
                        sName = line.split(": ")[1].strip()
                    if line.startswith("  rulebookDescription: "):
                        sDesc = line.split(": ")[1].strip("' \n").replace("[creature]", "a card bearing this sigil").replace("''", "'").capitalize()
                

                # Copy over sigil file
                sigPath = "/media/107zxz/Extra Files/Games/InscrExt/globalgamemanagers/Assets/Resources/art/gbc/cards/pixelabilityicons/" + sFileName
                
                if not os.path.exists(sigPath):
                    print("Missing sigil icon", sigPath)
                    continue

                shutil.copy(sigPath, "/home/107zxz/Documents/Games/Godot/LobbyTest/gfx/sigils/" + sName + ".png")

                ref_sigils[sCode] = {}
                ref_sigils[sCode]["name"] = sName
                ref_sigils[sCode]["description"] = sDesc





# Make sigil dict for export
sigils = {}
for sid in ref_sigils:
    if ref_sigils[sid]:
        sigils[ref_sigils[sid]["name"]] = ref_sigils[sid]["description"]
    else:
        print("Sigil found missing it's id!")


# Card overrides, needed because sometimes names don't match up
pixport_overrides = {
    # Beast
    "catundead": "cat_undead",
    "fieldmouse": "fieldmice",
    "fieldmouse_fused": "fieldmice_fused",
    
    # Wizard
    "masterorlu": "masterOB",
    "masterbleene": "masterBG",
    "mastergoranj": "masterGO",
}


cards = []

# Analyse cards
for cPath in cardPaths:

    print("Grabbing cards from", cPath)

    # Iterate all asset files
    for cardFile in os.listdir(cPath):
        # Am I an actual asset file?
        if ".meta" not in cardFile:
            with open(cPath + cardFile, "r") as cfHandle:
                lines = cfHandle.readlines()

                cName = ""
                cPortraitFileName = ""
                cSigs = []
                cAtk = -1
                cHp = -1
                cBloodCost = -1
                cBoneCost = -1
                cEnergyCost = -1
                cMoxCost = []
                cMeta = []
                

                for line in lines:
                    
                    # Meta categories, am I in act 2?
                    if line.startswith("  metaCategories: "):
                        mcRaw = line.split(": ")[1].strip()
                        mList = [mcRaw[i:i+8] for i in range(0, len(mcRaw), 8)]

                    # Grab card image
                    if line.startswith("  m_Name: "):
                        tName = line.split(": ")[1].strip().lower()

                        # Fix discrepencies
                        if tName in pixport_overrides:
                            tName = pixport_overrides[tName]

                        cPortraitFileName = "pixelportrait_" + tName + ".png"

                    # Name
                    if line.startswith("  displayedName: "):
                        cName = line.split(": ")[1].strip()
                    
                    # Attack
                    if line.startswith("  baseAttack: "):
                        cAtk = int(line.split(": ")[1])
                    
                    # Health
                    if line.startswith("  baseHealth: "):
                        cHp = int(line.split(": ")[1])

                    # Blood cost
                    if line.startswith("  cost: "):
                        cBloodCost = int(line.split(": ")[1])

                    # Bone cost
                    if line.startswith("  bonesCost: "):
                        cBoneCost = int(line.split(": ")[1])

                    # Energy cost
                    if line.startswith("  energyCost: "):
                        cEnergyCost = int(line.split(": ")[1])

                    # Mox cost
                    if line.startswith("  gemsCost: "):
                        # Parse mox cost into list of costs e.g. ["green", "blue"]
                        rawMoxCost = line.split(": ")[1].strip()

                        mList = [rawMoxCost[i:i+8] for i in range(0, len(rawMoxCost), 8)]

                        for mox in mList:
                            if mox == "00000000":
                                cMoxCost.append("green")
                            if mox == "01000000":
                                cMoxCost.append("orange")
                            if mox == "02000000":
                                cMoxCost.append("blue")
                    
                    # Sigils
                    if line.startswith("  abilities: "):
                        siglist = textwrap.wrap(line.split(": ")[1], 8)

                        for sigilhex in siglist:
                            sCode = int(sigilhex.strip("0"), 16)
                            if str(sCode) in ref_sigils:
                                cSigs.append(ref_sigils[str(sCode)]["name"])
                            else:
                                print("Unknown sigil", sCode, "referenced by card", cName)
                                continue

                
                # Is card from act 2?
                portPath = "/media/107zxz/Extra Files/Games/InscrExt/globalgamemanagers/Assets/Resources/art/gbc/cards/pixelportraits/" + cPortraitFileName

                if not os.path.exists(portPath):
                    print("Missing pixel portrait", portPath, "for card", cName, "discarding.")
                    continue
                    
                # Copy portrait
                shutil.copy(portPath, "/home/107zxz/Documents/Games/Godot/LobbyTest/gfx/pixport/" + cName + ".png")


                # Record card
                cards.append({
                    "name": cName,
                    "sigils": cSigs,
                    "attack": cAtk,
                    "health": cHp,
                    "blood_cost": cBloodCost,
                    "bone_cost": cBoneCost,
                    "energy_cost": cEnergyCost,
                    "mox_cost": cMoxCost
                })


gameInfo = {
    "cards": cards,
    "sigils": sigils
}

os.chdir("/home/107zxz/Documents/Games/Godot/LobbyTest/data")

json.dump(gameInfo, open("gameInfo.json", "w"), indent=4)