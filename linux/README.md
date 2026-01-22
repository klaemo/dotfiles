# Linux Server Setup

Scripts for setting up and securing Debian/Ubuntu servers.

## Initial Server Setup

### 1. Create a sudo user (run as root)

```bash
bash create-user.sh clemens
```

This will:
- Install `sudo` if not present
- Create the user with a password
- Add the user to the `sudo` group
- Copy SSH keys from `/root/.ssh/authorized_keys`

### 2. Test the new user

**Keep your root session open**, then in a new terminal:

```bash
ssh clemens@<server-ip>
sudo whoami  # should print: root
```

### 3. Harden SSH (run as the new user)

Once you've confirmed SSH key login works:

```bash
sudo bash harden-ssh.sh
```

This will:
- Disable root login (`PermitRootLogin no`)
- Disable password authentication (`PasswordAuthentication no`)
- Disable empty passwords
- Disable X11 forwarding
- Limit auth tries to 3
- Create a timestamped backup of the original config

### 4. Install packages and dotfiles

```bash
bash ~/.dotfiles/linux/setup.sh
```

### 5. Set up Tailscale + ufw (run as root)

```bash
sudo bash ~/.dotfiles/linux/setup-tailscale.sh
```

This will:
- Install and start Tailscale
- Prompt `tailscale up` if not already connected
- Enable ufw and set default deny incoming
- Allow SSH from anywhere and allow all traffic on `tailscale0`
