# Getting Started with Git

This page is for people who have **never used Git before**. It explains what Git is, how to get the FEATHER code onto your computer, and how to keep it up to date. 

If you already know Git, you probably just need the [[Getting Started – Installation & Toolbox Setup|User-Guide-Getting-Started]] page instead.

---

## What is Git, and why does FEATHER use it?

Git is a tool that keeps track of changes to code over time, and lets multiple people work on the same codebase without overwriting each other's work. GitLab is the website where you can access our copy of the FEATHER code that is hosted by GWDG.

You don't need to understand how Git works internally to use FEATHER — you mainly need to know how to:

1. **Clone** — download a copy of the code to your computer (only done once).
2. **Pull** — get the latest updates that other people have made (do this often).
3. **Commit** — save a snapshot of changes you made (only needed if you edit the toolbox code itself, not for normal analysis work).
4. **Push** — upload your saved changes back to GitLab so others can get them.

If you are only *using* FEATHER to run analyses (not modifying the toolbox code), you will mainly need **clone** and **pull**.

---

## Step 1: Install Git

Download and install **Git Bash** for Windows from [git-scm.com](https://git-scm.com/) if it isn't already installed on your computer. Accept the default options during installation unless you know you need something different.

---

## Step 2: Get your access token

You need a GitLab account and an access token (like a password specifically for Git) to download the FEATHER code. Ask AV (or your current toolbox maintainer) for an access token. Alternatively if you just want to use the toolbox, ask to become a member of the IAN gitlab group, everybody in there has the rights to clone and pull the toolbox, but not to commit any changes.

⚠️ **NEEDS INPUT FROM MAINTAINERS:** please add a short explanation of how to generate an access token in GitLab (Settings → Access Tokens), in case this needs to be self-served in the future.

---

## Step 3: Clone the repository (do this once per computer)

1. Create a folder on your computer where you want to keep the FEATHER code (e.g. `C:\Users\<you>\FoldersUnderGitControl\`).
2. Open **Git Bash** inside this folder (right-click inside the folder → "Git Bash Here", or open Git Bash and `cd` into the folder).
3. Run:

   ```bash
   git clone https://gitlab.gwdg.de/vavakou/invivoEphysFEATHER.git
   ```
   Or if you have a specific Token "Tokenname" with a key "abcdefg"  you can include it in the  command like this:

   ```bash
   git clone https://Tokenname:abcdefg@gitlab.gwdg.de/vavakou/invivoEphysFEATHER.git
   ```
4. Otherwise just log in with your email and the access token you were given when prompted by the system (use the token as the password).

This creates a new folder called `invivoEphysFEATHER` containing the full toolbox code. This is the folder you should point `tb_path` to in your `startup.m` script (see [[Getting Started – Installation & Toolbox Setup|User-Guide-Getting-Started]]).

---

## Step 4: Get updates (do this regularly)

Other people are frequently improving FEATHER. To get their changes:

1. Open Git Bash inside your `invivoEphysFEATHER` folder.
2. Run:

   ```bash
   git pull
   ```

This downloads and merges in any new changes. Do this **every time before you start a new day of analysis**, so you're working with the current version of the toolbox.

---

## Command cheat sheet

| What you want to do | Command | When to use it |
|---|---|---|
| Download the code for the first time | `git clone <url>` | Once, when setting up a new computer |
| Get the latest updates | `git pull` | Regularly — ideally every time before you start working |
| Check what's changed locally | `git status` | Before committing, to see what you've edited |
| Save a snapshot of your changes | `git add .` then `git commit -m "short description"` | Only if you're editing toolbox code (developers) |
| Upload your saved changes | `git push` | Only if you're editing toolbox code (developers) |
| See the history of changes | `git log` | If you want to see what's changed and when |

---

## Common troubleshooting

**"fatal: repository not found" or authentication errors**
Double check you're using the access token (not your regular GitLab password) when prompted, and that the token hasn't expired. Ask your maintainer for a new one if needed.

**"Your local changes would be overwritten by merge"**
This means you've edited a file that was also changed on GitLab, and Git doesn't know which version to keep. If you didn't mean to edit toolbox files, this is a sign you should not be editing files directly inside the shared toolbox folder — keep your personal analysis scripts (including your personalized `startup.m` copy) outside the FEATHER repository folder (e.g. in you home folder).

**Git Bash can't find `git` / command not recognized**
Git was likely not installed correctly, or you're using a different terminal (e.g. Command Prompt/PowerShell) instead of Git Bash. Re-open Git Bash specifically, or reinstall Git.

**I don't know if I'm "inside" the right folder in Git Bash**
Type `pwd` (print working directory) in Git Bash to see where you currently are, and `ls` to list the files/folders there.

---

