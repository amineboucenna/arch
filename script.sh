#!/bin/bash

# Welcome message
echo -e "\e[33mWelcome to ArchLinux Installation Script. After this installation, you will be able to say \e[36m'I use Arch btw.'\e[0m\e[0m"

# Printing disks
echo "These are your disks:"
lsblk -l

# Asking the user for the disk to use for installation
echo "Please insert the disk name that you wish to use for installation (e.g., /dev/sdX): "
read -r disk
clear
# Getting confirmation from the user
valid_input=false

while [ "$valid_input" = false ]; do
    echo "This will erase all data. Are you sure you want to continue? (yes/y or no/n): "
    read -r confirmation

    if [[ "$confirmation" == "yes" || "$confirmation" == "y" ]]; then
        echo "Continuing..."
        valid_input=true
        # Continue with the desired actions after user confirmation
    elif [[ "$confirmation" == "no" || "$confirmation" == "n" ]]; then
        echo "Aborting..."
        exit 0
    else
        echo "Invalid input. Please enter either 'yes', 'y', 'no', or 'n'."
    fi
done

echo -e "o\nw" | sudo fdisk "$disk"
echo "Your disk is ready for installation..."
clear
# Asking the user about the installation type: EFI or MBR
valid_input=false

while [ "$valid_input" = false ]; do
    echo "Are you using GPT (EFI) or MBR for your installation? (Enter 1 for EFI or 2 for MBR): "
    read -r installation_type

    if [ "$installation_type" = "1" ]; then
        echo "Creating partitions for EFI (GPT) installation..."
        sudo parted "$disk" mklabel gpt
        sudo parted "$disk" mkpart primary fat32 1MiB 500MiB
        sudo parted "$disk" set 1 esp on
        sudo parted "$disk" mkpart primary ext4 500MiB 100%
        mkfs.fat -F32 "$disk"1
        mkfs.ext4 "$disk"2 
        valid_input=true
    elif [ "$installation_type" = "2" ]; then
        echo "Creating partitions for MBR installation..."
        sudo parted "$disk" mklabel msdos
        sudo parted "$disk" mkpart primary ext4 1MiB 100%
        mkfs.ext4 "$disk"1
        valid_input=true
    else
        echo "Invalid input. Please enter either 1 or 2."
    fi
done
clear

# keyboard layout
echo -e "Please enter one keyboard layout (ex us, fr see more at archlinux wiki ): "
read keyboard_layout

# keyboard layout
valid_input=false
while [ "$valid_input" = false ]; do
    echo "Plase enter root password: "
    read root_password
    echo "confirm root password: "
    read root_password_confirm
    if ["$root_password" = "$root_password_confirm"]; then 
        valid_input = true
    else
        echo "The password given are not the same!"
        sleep 1s
        clear
    fi
done

"$valid_input" = false 
echo -e "Lets create a user\nGive him a username: "
read username
while [ "$valid_input" = false ]; do
    echo "Plase enter $username password: "
    read user_password
    echo "confirm $username password: "
    read user_password_confirm
    if ["$user_password" = "$user_password_confirm"]; then 
        valid_input = true
     else
        echo "The password given are not the same!"
        sleep 1s
        clear
    fi
done
clear

# Asking the user his favorite desktop manager
valid_input=false

while [ "$valid_input" = false ]; do
    echo -e "Please enter your favorite desktop manager:\n[\e[1;37m1\e[0m] \e[1;37mi3\e[0m\n[\e[1;37m2\e[0m] \e[1;37mKDE Plasma\e[0m\n[\e[1;37m3\e[0m] \e[1;37mGNOME\e[0m\n[\e[1;37m4\e[0m] \e[1;37mXFCE4\e[0m\n[\e[1;37m5\e[0m] \e[1;37mDeepin\e[0m"
    read -r desktop_manager_choice

    case "$desktop_manager_choice" in
        "1")
            desktop_manager="i3"
            valid_input=true
            ;;
        "2")
            desktop_manager="KDE Plasma"
            valid_input=true
            ;;
        "3")
            desktop_manager="GNOME"
            valid_input=true
            ;;
        "4")
            desktop_manager="XFCE4"
            valid_input=true
            ;;
        "5")
            desktop_manager="Deepin"
            valid_input=true
            ;;
        *)
            echo "Invalid input. Please enter a number from 1 to 5."
            ;;
    esac
done
echo "You selected $desktop_manager as your favorite desktop manager."
sleep 2s
clear
# custom packages
echo "do you want to install any additional packages (ex firefox vlc ): "
read additional_packages
# Downloading packages packages based on the window manager
window_manager_packages=""

case "$desktop_manager" in
    "i3")
        window_manager="i3"
        ;;
    "KDE Plasma")
        window_manager="plasma"
        ;;
    "GNOME")
        window_manager="gnome"
        ;;
    "XFCE4")
        window_manager="xfce4"
        ;;
    "Deepin")
        window_manager="deepin"
        ;;
    *)
        echo "Invalid desktop manager selection."
        ;;
esac

echo "enter a session manager : "
read session_manager

echo "Do you want to user XORG or WAYLAND: "
read xorg_wayland
clear
# Mounting the partitions
if [ "$installation_type" = "1" ]; then
    mount "$disk"2 /mnt
    echo "Creating /mnt/boot/efi directory..."
    mkdir /mnt/boot/
    mkdir /mnt/boot/efi
    echo "Mounting the EFI partition into /mnt/boot/efi..."
    mount "$disk"1 /mnt/boot/efi
    echo "EFI partition mounted successfully."
else
    # mbr
    mount "$disk"1 /mnt
    echo "MBR partition mounted successfully."    
fi

# Retrieving the fastest servers
echo "Retrieving the fastest servers for a faster installation..."
reflector --latest 3  --sort rate --save /etc/pacman.d/mirrorlist

sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 15/' /etc/pacman.conf

echo "Downloading packages..."
pacstrap /mnt linux linux-firmware base base-devel grub efibootmgr networkmanager sudo nano $xorg_wayland $window_manager $additional_packages $session_manager


echo "Packages downloaded and installed successfully."
clear
# Generating fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Mounting chroot
arch-chroot /mnt /bin/bash <<EOF
# Configuring
sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 15/' /etc/pacman.conf
ln -sf /usr/share/zoneinfo/Africa/Algiers /etc/localtime
hwclock --systohc
sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo "root:$root_password" | chpasswd
useradd -m $username -G wheel
echo "$username:$user_password" | chpasswd
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=$keyboard_layout > /etc/vconsole.conf
echo $host_name > /etc/hostname

systemctl enable NetworkManager
systemctl enable $session_manager

if [ "$installation_type" = "1" ]; then
    echo "Installing grub for EFI"
    grub-install --target=x86_64-efi --efi-directory=/boot/efi
    grub-mkconfig -o /boot/grub/grub.cfg
elif [ "$installation_type" = "2" ]; then
    echo "Installing grub for MBR"
    grub-install --target=i386-pc "$disk"
    grub-mkconfig -o /boot/grub/grub.cfg
fi
clear
echo "Installation complete"

exit

umount -R /mnt

"Rebooting..."
sleep 2s
reboot
EOF
