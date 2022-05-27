import os
import json
from re import S
import shutil
import textwrap
from weakref import ref

basePath = "/media/107zxz/Extra Files/Games/InscrExt/globalgamemanagers/Assets/Resources/data/"
sigilPaths = ["abilities/part1/", "abilities/gbc/", "abilities/part3/"]
cardPaths = ["cards/nature/", "cards/technology/", "cards/undead/", "cards/wizard/"]

initialDir = os.getcwd()
os.chdir(basePath)

# Analyse sigils
sicon_overrides = {
    # Mox garbo
    "gaingemblue": "gaingem_blue",
    "gaingemorange": "gaingem_orange",
    "gaingemgreen": "gaingem_green",
    "gaingemtriple": "gaingem_all",

    # Dice roll garbo
    "activated_randompowerbone": "activated_dicerollbone",
    "activated_randompowerenergy": "activated_dicerollenergy",
    "activated_sacrificedrawcards": "activated_sacrificedraw",
}

working_sigils = [
    "Airborne",
    "Mighty Leap",
    "Fecundity",
    "Unkillable",
    "Blue Mox",
    "Green Mox",
    "Orange Mox",
    "Great Mox",
    "Rabbit Hole",
    "Touch of Death",
    "Many Lives",
    "Trifurcated Strike",
    "Battery Bearer",
    "Repulsive",
    "Brittle",
    "Worthy Sacrifice",
    "Gem Dependant"
]

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

                        # Overrides
                        if tName in sicon_overrides:
                            sFileName = "pixelability_" + sicon_overrides[tName] + ".png"
                        else:
                            sFileName = "pixelability_" + tName + ".png"
                    if line.startswith("  ability: "):
                        sCode = line.split(": ")[1].strip()
                    if line.startswith("  rulebookName: "):
                        sName = line.split(": ")[1].strip()

                        # Mistake in inscryption files
                        if sCode == "68":
                            print('DD')
                            sName = "Double Death"
                    
                    if line.startswith("  rulebookDescription: "):
                        sDesc = line.split(": ")[1].strip("' \n").replace("[creature]", "a card bearing this sigil").replace("''", "'").capitalize()
                

                # Copy over sigil file
                sigPath = "/media/107zxz/Extra Files/Games/InscrExt/globalgamemanagers/Assets/Resources/art/gbc/cards/pixelabilityicons/" + sFileName
                
                if not os.path.exists(sigPath):
                    if "gbc" in sPath:
                        print("Missing sigil icon", sigPath)
                    continue

                shutil.copy(sigPath, "/home/107zxz/Documents/Games/Godot/LobbyTest/gfx/sigils/" + sName + ".png")

                ref_sigils[sCode] = {}
                ref_sigils[sCode]["name"] = sName
                ref_sigils[sCode]["description"] = sDesc





# Make sigil dict for export
sigils = {}
for sid in ref_sigils:
    if ref_sigils[sid] and ref_sigils[sid]["name"]:
        sigils[ref_sigils[sid]["name"]] = ref_sigils[sid]["description"]
    else:
        print("Sigil found missing its id!")


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
    "moxdualbg": "moxBG",
    "moxdualgo": "moxGO",
    "moxdualob": "moxOB",

    # Robot
    "leapbot": "leapingbot",
    "techmoxtriple": "gemmodule",
    "plasmagunner": "energygunner",
    "insectodrone": "insectobot",
    "closerbot": "gunnerbot",

}


cards = [
    # Cards that can't be auto-found / custom cards
    {
        "name": "Starvation",
        "sigils": [
            "Repulsive"
        ],
        "attack": 1,
        "health": 1,
        "blood_cost": 0,
        "bone_cost": 0,
        "energy_cost": 0,
        "mox_cost": []
    }
]

# Cards not to include in deck editor
banned_cards = [
    # Beast
    "Undead Cat",
    "Spore Mice",
    "Squirrel",
    "Rabbit",

    # Undead
    "Sporedigger",
    "Bone Lord's Horn",
    "Broken Obol",
    "Skeleton",

    # Energy
    "Sentry Spore",

    # Wizard
    "Magnus Mox",
    "Force Mage",
    "Blue Sporemage",
    "Ruby Mox",
    "Emerald Mox",
    "Sapphire Mox",

    # Other / non-playable
    "Starvation",
    "Burrowing Trap",
    "Inspector",
    "Melter"
]

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
                                cMoxCost.append("Green")
                            if mox == "01000000":
                                cMoxCost.append("Orange")
                            if mox == "02000000":
                                cMoxCost.append("Blue")
                    
                    # Sigils
                    if line.startswith("  abilities: "):
                        siglist = textwrap.wrap(line.split(": ")[1], 8)

                        for sigilhex in siglist:
                            sCode = int(sigilhex[0:2], 16)
                            if str(sCode) in ref_sigils:
                                cSigs.append(ref_sigils[str(sCode)]["name"])
                            else:
                                # print("Unknown sigil", sCode, "referenced by card", cName)
                                continue

                
                # Is card banned?
                # if cName in banned_cards:
                #     print("Card", cName, "is banned!")
                #     continue

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
    "sigils": sigils,
    "banned_cards": banned_cards,
    "working_sigils": working_sigils
}

os.chdir("/home/107zxz/Documents/Games/Godot/LobbyTest/data")

json.dump(gameInfo, open("gameInfo.json", "w"), indent=4)