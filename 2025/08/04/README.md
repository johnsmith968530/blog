```text
$Source: /home/x/Dropbox/2/src/blog/2025/08/04/RCS/README.md,v $
$Date: 2025/08/05 05:31:08 $
$Revision: 1.11 $
```

# h353
* Macbook Air
  * 13-inch
  * Apple M4
  * 32 GB Unified Memory
  * 13.6-inch display (2560 x 1664)
  * 1 TB HD (actually 994.66 GB)
  * Currently on macOS Sequoia 15.6
* Installed Xcode via the App Store
* Installed Homebrew (https://brew.sh/) via
```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
followed by
```zsh
echo >> /Users/x/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/x/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```
as recommended in the output of the previous command.
* Installed Dropbox from the app I downloaded from the Dropbox website (I didn't use Homebrew).
  * For some critical applications, I like to download them as the original developers of the app intended. Over the years, I've found that re-packaged apps sometimes don't work as intended.
  * Also, I'd like Dropbox and other critical apps to keep working if I accidentally trash my Homebrew setup.
  * Also, for some apps, I'd like to keep around old versions that aren't auto-updated by Homebrew. Sometimes, the new version of some critical app breaks some feature I really need, and I'd like to be able to roll back to the old version.
* Installed [KeepassXC](https://keepassxc.org/) 2.7.10-arm64 from the app I downloaded from the website.
* Installed [neovim](https://neovim.io/) 0.11.3 via `brew install neovim`.
* Installed [borg](https://www.borgbackup.org/) version 1.4.1 via `brew install borgbackup`.
* Installed [GnuPG](https://www.gnupg.org/) version 2.4.8 via `brew install gnupg`.
  * Note that it's not necessary to use `brew intall gnupg2`, as mentioned here:
    * https://stackoverflow.com/questions/54895263/how-to-install-gpg2-via-homebrew
* Installed [RCS](https://www.gnu.org/software/rcs/) via `brew install rcs`.
* Installed [Anki](https://apps.ankiweb.net/) 25.07.5 via the app I downloaded from the website.
* Installed [Node.js](https://nodejs.org/en/download):
  * `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash`
  * After restarting the shell, I did `nvm install 22`, which installed the latest LTS version.
* Installed [Rust](https://www.rust-lang.org/tools/install) via:
  * `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
  * I chose the default installation.
* Installed [GHCup (Haskell)](https://www.haskell.org/ghcup/install/):
  * `curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh`
  * I chose defaults for everything.
* Installed the [Claude](https://claude.ai/download) app from the website.
* Installed the [ChatGPT](https://chatgpt.com/download/) app from the website.

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
