
# Create pi/raspberry login
if id "$1" >/dev/null 2>&1; then
    echo 'user found'
else
    echo "creating pi user"
    useradd pi -b /home
    usermod -a -G sudo pi
    mkdir /home/pi
    chown -R pi /home/pi
fi
echo "pi:raspberry" | chpasswd

apt-get update
wget https://git.io/JJrEP -O install.sh
chmod +x install.sh

sed -i 's/# AllowedCPUs=4-7/AllowedCPUs=4-7/g' install.sh

./install.sh
rm install.sh

# Changing default shell
echo "Setting default shell to bash for user pi"
chsh -s $(which bash) pi

# Remove extra packages 
echo "Purging extra things"
apt-get remove -y gdb gcc g++ linux-headers* libgcc*-dev
apt-get remove -y snapd
apt-get autoremove -y


echo "Installing additional things"
sudo apt-get update
apt-get install -y network-manager net-tools libatomic1 linuxptp v4l-utils
# mrcal stuff
apt-get install -y libcholmod3 liblapack3 libsuitesparseconfig5

# See default options and info:
# https://github.com/richardcochran/linuxptp/blob/v3.1.1/configs/default.cfg
# https://github.com/richardcochran/linuxptp/blob/v3.1.1/ptp4l.8
echo "Setting up linuxptp as a service"
# Changing some configurations
sed -i '/^slaveOnly.*/c\slaveOnly               1' /etc/linuxptp/ptp4l.conf
sed -i '/^clock_servo.*/c\clock_servo             linreg' /etc/linuxptp/ptp4l.conf
sed -i '/^logging_level.*/c\logging_level           7' /etc/linuxptp/ptp4l.conf
sed -i '/^delay_mechanism.*/c\delay_mechanism         Auto' /etc/linuxptp/ptp4l.conf
sed -i '/^time_stamping.*/c\time_stamping           software' /etc/linuxptp/ptp4l.conf
# Start and enable the service so it always runs
systemctl start ptp4l@eth0.service
systemctl enable ptp4l@eth0.service

cat > /etc/netplan/00-default-nm-renderer.yaml <<EOF
network:
  renderer: NetworkManager
EOF

rm -rf /var/lib/apt/lists/*
apt-get clean

rm -rf /usr/share/doc
rm -rf /usr/share/locale/
