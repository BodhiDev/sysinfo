# sysinfo
A simple yad based system Info application

**It displays system and hardware information.** In particular: CPU, GPU, Memory, Disks, PCI, Kernel Modules, Battery, and Network.  

It also allows you to copy the report, which you can then share by pasting with **CTRL+V** or right-click -> Paste.

<img width="729" height="485" alt="shot-2026" src="https://github.com/user-attachments/assets/076eaedd-b1ee-4ffb-b800-859a0f51aeaa" />

### Installation:

- **Build:**  `dpkg-buildpackage -us -uc -b`

- **Install:**  `sudo dpkg -i ../bodhi-sysinfo_*.deb`

- **Uninstall:**  `sudo apt remove bodhi-sysinfo`
