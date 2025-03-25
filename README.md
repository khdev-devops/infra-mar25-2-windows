# Övning: Windows-infrastruktur med enkel webbsida

## Syfte
Denna övning ger dig praktisk erfarenhet av att automatisera uppsättning av Windows-server i AWS med hjälp av OpenTofu (Terraform) och Ansible. Du får också installera en webbserver (IIS) och en enkel webbsida.

**Tidsåtgång:** ca 1.5 timme. Vissa steg är förberedda, andra är markerade med `TODO` där du själv ska söka information och fylla i.

---

## Kort om teknikerna

### IIS - Internet Information Services
Microsofts webbserver för att hosta t.ex. ASP.NET-webbappar på Windows. Liknar Apache/Nginx.
- Mer info: https://learn.microsoft.com/iis/

### WinRM - Windows Remote Management
WinRM används för att få fjärråtkomst till Windows. Vi använder detta för att konfigurera instansen via Ansible.
- Mer info: https://learn.microsoft.com/windows/win32/winrm/

---

## Del 1: CloudShell - Skapa EC2-instans
1. Starta AWS CloudShell via AWS Console.
2. Klona detta GitHub-repo.
3. Generera ett **RSA-nyckelpar** (krävs för att hämta Windows-lösenordet senare):
    ```bash
    ssh-keygen -P "" -t rsa -b 4096 -m pem -f ~/.ssh/windows-key.pem
    ```
    - Skapar:
      - `~/.ssh/windows-key.pem` (privat nyckel, ladda ner till din laptop)
      - `~/.ssh/windows-key.pem.pub` (publik nyckel)

4. Installera och använd OpenTofu för att skapa en Windows-instans:
   - EC2: t3.micro
   - AMI: Windows Server 2022
   - Säkerhetsgrupp:
     - Tillåt **port 80** från alla (HTTP till IIS)
     - Tillåt **port 5985** från CloudShells IP (WinRM)
     - Tillåt **port 3389** från din egen laptops IP (RDP)

> **Skelett finns i `tofu/main.tf` men innehåller TODO-kommentarer där du behöver komplettera.**

Läs mer om EC2 via Terraform:
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

---

## Del 2: Logga in med RDP och konfigurera WinRM

### Steg 1: Hämta Windows-lösenordet
För att logga in som `Administrator` på din Windows-instans behöver du ett tillfälligt lösenord 
som genereras av EC2 vid uppstart. Så här gör du:

1. Gå till **EC2 Console** → välj din instans
2. Klicka på **Actions > Security > Get Windows Password**
3. Ladda upp din **privata nyckel** (t.ex. `my-windows-key` från Del 1)
4. Klicka **Decrypt Password**

Du ser nu ett engångslösenord till `Administrator`-kontot

> Om du inte ser knappen "Get Windows Password": kontrollera att instansen är i status `running` 
och att minst 4–5 minuter har gått efter uppstart.

### Steg 2: Anslut via RDP

1. Gå till EC2 Console → din instans → **Connect > RDP client**
2. Ladda ner `.rdp`-filen och öppna den på din dator
3. Logga in med:
   - **Username:** `Administrator`
   - **Password:** (lösenordet du hämtade ovan)

Har du inte en RDP-klient installerad?
- **Windows:** "Remote Desktop Connection" finns förinstallerad (sök på `mstsc`)
- **Mac:** Ladda ner [Windows App](https://apps.apple.com/se/app/microsoft-remote-desktop/id1295203466)
- **Linux:** Använd t.ex. `remmina` eller `xfreerdp`

### Steg 3: Aktivera WinRM
För att kunna styra Windows-instansen via Ansbible slår vi på WinRM och öppnar en port i Windows firewall så att vi kan komma åt WinRM.

Logga in i Windows, starta Powershell (skriv in `Powershell` i sökfältet i nedre vänstra delen av skärmen) och kör följande PowerShell-kommandon:

```powershell
winrm quickconfig -quiet
Enable-PSRemoting -Force
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value true
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value true
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
  -Name "LocalAccountTokenFilterPolicy" -Value 1 -PropertyType DWord -Force
New-NetFirewallRule -DisplayName "WinRM Port 5985" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow
```

Läs mer om att nå WinRM med Ansible:
- https://docs.ansible.com/ansible/latest/user_guide/windows_winrm.html#windows-winrm

---

## Del 3: Ansible från CloudShell

1. Skapa din egen **inventory-fil** (`ansible/inventory`) med hjälp av exempelfilen (`ansible/inventory.example`). 
- Se till att fylla i dina egna värden där det behövs.

2. Testa Ansible mot Windows:
```bash
ansible windows -i inventory -m win_ping
```

3. Uppdatera Playbook-filen `ansible/playbook.yml` (innehåller TODO-kommentarer där du själv ska fylla i). 

  - Playbooken
    - Installerar IIS
    - Laddar upp en enkel webbsida (index.html)

4. När du är klar med ändringar, kör playbook:
```bash
ansible-playbook -i inventory playbook-windows.yml
```
5. Besök webbsidan från din egen dators webbläsare för att bekräfta att allt funkar.

Läs mer:
- https://docs.ansible.com/ansible/latest/collections/ansible/windows/index.html

---

## Exempelstruktur
```
infra/
  main.tf              # Terraformfil med TODO
  variables.tf         # Definitioner av variabler
  terraform.tfvars     # Dina egna variabelvärden
  outputs.tf           # IP som resultat från tofu apply
ansible/
  inventory            # Instans-IP och lösenord här
  playbook.yml         # Playbook med automatisering
  files/
    index.html       # Enkel webbsida
```

---

## Resultat
- En fungerande Windows EC2-instans
- IIS med enkel webbsida

---

## Städa upp!

Ta bort EC2-instansen och relaterad infrastruktur skapad av OpenTofu (i CloudShell i projektets katalog):
```bash
tofu destroy
```