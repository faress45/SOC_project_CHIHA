# SOC_project_CHIHA - Tuto Making Qsys Components

Projet réalisé dans le cadre du tutoriel **"Making Qsys Components"** d'Altera (Quartus II 13.0).

##  Objectif

L'objectif est de créer un **composant Qsys personnalisé** (un registre 16 bits avec interface Avalon) et de l'intégrer dans un système embarqué **Nios II** sur une carte **Altera DE1**.

---

##  Point de départ

Ce projet est basé sur l'exemple de base fourni par Altera University Program :
```
altera\13.0sp1\University_Program\NiosII_Computer_Systems\DE1\DE1_Basic_Computer\
```

Le système de base **DE1_Basic_Computer** fournit :
-  Processeur soft-core Nios II/e
-  Mémoires On-Chip / SDRAM / SRAM
-  Port UART (communication série)
-  LEDs, switchs et boutons
-  Afficheurs 7 segments HEX0 à HEX3

---

##  Modifications apportées

### 1️ Création des composants custom

#### **reg16.vhd** - Registre 16 bits synchrone
- Reset actif bas (`resetn`)
- Écriture octet par octet contrôlée par `byteenable[1:0]`
- Sortie Q 16 bits

#### **reg16_avalon_interface.vhd** - Interface Avalon Memory-Mapped
Interface esclave Avalon complète autour du registre reg16 :

| Signal | Direction | Description |
|--------|-----------|-------------|
| `clock` | Entrée | Horloge système |
| `resetn` | Entrée | Reset actif bas |
| `writedata[15:0]` | Entrée | Données à écrire |
| `readdata[15:0]` | Sortie | Données lues |
| `write` | Entrée | Signal d'écriture |
| `read` | Entrée | Signal de lecture |
| `chipselect` | Entrée | Sélection du composant |
| `byteenable[1:0]` | Entrée | Sélection des octets |
| `Q_export[15:0]` | Sortie | **Conduit exporté** vers afficheurs |

#### **hex7seg.vhd** - Décodeur hexadécimal → 7 segments
- Convertit un nibble (4 bits) en affichage 7 segments
- Logique active bas
- **Correction appliquée** : direction du port changée de `(0 TO 6)` à `(6 DOWNTO 0)` pour correspondre aux pins DE1
- Instancié **4 fois** dans le top-level pour afficher les 4 nibbles du registre

### 2️ Système Qsys (nios_system.qsys)

Architecture du système embarqué :

```
Nios II/e (soft-core processor)
    ↓
On-Chip Memory (programme + données)
    ↓
Périphériques :
├── SDRAM Controller
├── SRAM Controller
├── UART (port série)
└── reg16_avalon_interface (CUSTOM) ← Registre 16 bits
    └── Conduit exporté "to_hex" vers top-level
```

**Adresse de base du registre** : `0x00000000`

### 3️ Top-level (DE1_Basic_Computer.vhd)

**Désactivation du composant HEX3_HEX0 natif** (ports mis en commentaire)

**Affichage du registre sur les 7 segments** :
```
Qsys (to_hex_readdata)
    ↓
4 instances de hex7seg :
├── to_HEX[3:0]   → hex7seg → HEX0
├── to_HEX[7:4]   → hex7seg → HEX1
├── to_HEX[11:8]  → hex7seg → HEX2
└── to_HEX[15:12] → hex7seg → HEX3
```

---

##  Architecture du projet

```
SOC_project_CHIHA/
│
├── ip_modules/                              # Composants VHDL custom
│   ├── reg16.vhd                            # Registre 16 bits
│   ├── reg16_avalon_interface.vhd           # Interface Avalon MM
│   └── hex7seg.vhd                          # Décodeur 7 segments (corrigé)
│
├── nios_system/                             # Système Qsys généré
│   └── (fichiers générés par Quartus)
│
├── DE1_Basic_Computer.vhd                   # Top-level VHDL (modifié)
├── DE1_Basic_Computer.qpf                   # Fichier projet Quartus
├── DE1_Basic_Computer.qsf                   # Pin assignments
├── nios_system.qsys                         # Système Qsys (modifié)
├── reg16_avalon_interface_hw.tcl            # Fichier TCL du composant Qsys
├── sdram_pll.vhd                            # PLL SDRAM
├── schéma.png                               # Schéma du projet
├── gitignore.txt                            # Fichiers ignorés Git
└── README.md                                # Ce fichier
```

---

##  Comment tester

### Compilation et programmation

1. **Ouvrir** le projet dans **Quartus II 13.0** (fichier `DE1_Basic_Computer.qpf`)
2. **Compiler** le projet : `Processing > Start Compilation`
3. **Générer** le système Qsys si nécessaire : `Tools > Qsys`
4. **Programmer** la carte DE1 avec le fichier `.sof` généré : `Tools > Programmer`

### Test du registre

1. Ouvrir **Altera Monitor Program**
2. Créer un projet avec `nios_system.qsys`
3. Compiler et télécharger le système sur la carte
4. Aller à l'adresse mémoire `0x00000000` dans l'onglet **Memory**
5. **Modifier la valeur du registre** → observer les afficheurs 7 segments HEX0 à HEX3 en temps réel

**Exemple** :
- Écrire `0x1234` → affiche **1 2 3 4** sur HEX3 HEX2 HEX1 HEX0
- Écrire `0xABCD` → affiche **A B C D** sur HEX3 HEX2 HEX1 HEX0

---

##  Matériel requis

-  Carte **Altera DE1**
-  **Quartus II 13.0sp1** (ou version compatible)
-  **Altera Monitor Program**

---

##  Références

- Tutoriel : "Making Qsys Components" - Altera University Program
- Carte : Altera DE1 Development Board
- Processeur : Nios II soft-core
- Interface : Avalon Memory-Mapped (Altera Interconnect Fabric)

---

##  Résumé des modifications

| Fichier | Modification |
|---------|-------------|
| `reg16.vhd` |  Créé - Registre 16 bits synchrone |
| `reg16_avalon_interface.vhd` |  Créé - Interface Avalon MM |
| `hex7seg.vhd` |  Corrigé - Direction du port + table de vérité |
| `DE1_Basic_Computer.vhd` |  Modifié - Désactivation HEX natif, ajout décodeurs |
| `nios_system.qsys` |  Modifié - Ajout du composant reg16_avalon_interface |
| `reg16_avalon_interface_hw.tcl` |  Créé - Description TCL du composant Qsys |

---

**Projet créé dans le cadre d'apprentissage des composants Qsys personnalisés sur Altera/Intel FPGA** 