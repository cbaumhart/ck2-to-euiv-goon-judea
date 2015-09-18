function fixjudea {
    $oldtag = " = Z13" #the tag from the converted game
    $newtag = " = JUD #Former Z13" #make sure this is unique
    #location of mod
    $modlocationtxt = "C:\Users\cbaumhart\Documents\Paradox Interactive\Europa Universalis IV\mod\Judea"
    
    $modcontent = Get-ChildItem -Path $modlocationtxt -Recurse 

    $modcontent | foreach {
        if( $psitem.fullname.ToString().EndsWith("txt") -eq $True){
        (Get-Content $psitem.FullName) | ForEach-Object {$_ -replace $oldtag, $newtag } | Add-Content ($psitem.FullName+".tmp")
        Remove-Item $psitem.FullName
        Rename-Item ($psitem.FullName+".tmp") $psitem
        }
    }
}

function fixprovinces {
    #$provinceloc = "C:\users\cbaumhart\documents\paradox interactive\europa universalis iv\mod\judea\history\provinces"
    $provinceloc = "C:\Users\cbaumhart\Documents\GitHub\ck2-to-euiv-goon-judea\history\provinces"
    $provcontent = Get-ChildItem -Path $provinceloc -Filter *-*.txt
    $provcontent | foreach {
        Write-Host 'Processing ' $PSItem
        $newcontent = ($PSItem.FullName+".tmp").ToString()
        $tempcontent = Get-Content $PSItem.FullName
        #$PSItem.Item(0) | set-content $newcontent
        $i = 0
        while ($tempcontent[$i] -ne '1444.11.11 = {'){
            Add-Content -Value $tempcontent[$i] -Path $newcontent
           $i++
        }
        if(($tempcontent | select-string -Pattern "discovered_by = western" -SimpleMatch) -in "discovered_by = western"){
            Add-Content -Value 'discovered_by = judean' -Path $newcontent
        }
        Add-Content -Value 'hre = no' -Path $newcontent
        #create Forms
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        $objForm = New-Object System.Windows.Forms.Form 
        $objForm.Text = "Data Entry Form"
        $objForm.Size = New-Object System.Drawing.Size(300,200) 
        $objForm.StartPosition = "CenterScreen"
        
        $OKButton = New-Object System.Windows.Forms.Button
        $OKButton.Location = New-Object System.Drawing.Size(75,120)
        $OKButton.Size = New-Object System.Drawing.Size(75,23)
        $OKButton.Text = "OK"
        $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $objForm.AcceptButton = $OKButton
        $objForm.Controls.Add($OKButton)

        $CancelButton = New-Object System.Windows.Forms.Button
        $CancelButton.Location = New-Object System.Drawing.Size(150,120)
        $CancelButton.Size = New-Object System.Drawing.Size(75,23)
        $CancelButton.Text = "Cancel"
        $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $objForm.CancelButton = $CancelButton
        $objForm.Controls.Add($CancelButton)

        $objLabel = New-Object System.Windows.Forms.Label
        $objLabel.Location = New-Object System.Drawing.Size(10,20) 
        $objLabel.Size = New-Object System.Drawing.Size(280,20) 
        $objLabel.Text = ("Province: " + $PSItem)
        $objForm.Controls.Add($objLabel) 

        $objLabelTax = New-Object System.Windows.Forms.Label
        $objLabelTax.Location = New-Object System.Drawing.Size(10,40) 
        $objLabelTax.Size = New-Object System.Drawing.Size(80,20) 
        $objLabelTax.Text = "Tax"
        $objForm.Controls.Add($objLabelTax)

        $objLabelProd = New-Object System.Windows.Forms.Label
        $objLabelProd.Location = New-Object System.Drawing.Size(90,40) 
        $objLabelProd.Size = New-Object System.Drawing.Size(80,20) 
        $objLabelProd.Text = "Production"
        $objForm.Controls.Add($objLabelProd)

        $objLabelMan = New-Object System.Windows.Forms.Label
        $objLabelMan.Location = New-Object System.Drawing.Size(170,40) 
        $objLabelMan.Size = New-Object System.Drawing.Size(80,20) 
        $objLabelMan.Text = "Manpower"
        $objForm.Controls.Add($objLabelMan)

        $objTextBoxTax = New-Object System.Windows.Forms.TextBox 
        $objTextBoxTax.Location = New-Object System.Drawing.Size(10,60) 
        $objTextBoxTax.Size = New-Object System.Drawing.Size(80,20) 
        $objForm.Controls.Add($objTextBoxTax) 

        $objTextBoxProd = New-Object System.Windows.Forms.TextBox 
        $objTextBoxProd.Location = New-Object System.Drawing.Size(90,60) 
        $objTextBoxProd.Size = New-Object System.Drawing.Size(80,20) 
        $objForm.Controls.Add($objTextBoxProd)

        $objTextBoxMan = New-Object System.Windows.Forms.TextBox 
        $objTextBoxMan.Location = New-Object System.Drawing.Size(170,60) 
        $objTextBoxMan.Size = New-Object System.Drawing.Size(80,20) 
        $objForm.Controls.Add($objTextBoxMan)

        $objForm.Topmost = $True

        $objForm.Add_Shown({$objForm.Activate()})
        $result = $objForm.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK)
        {
            $btinput = $objTextBoxTax.Text
            $bpinput = $objTextBoxProd.Text
            $bminput = $objTextBoxMan.Text
        }

        #prompt for base tax, production, and manpower
        Add-Content -Value ('base_tax = ' + $btinput) -path $newcontent
        Add-Content -Value ('base_production = ' + $bpinput) -path $newcontent
        Add-Content -Value ('base_manpower = ' + $bminput) -path $newcontent
        #add last part of history
        Add-Content -Value $tempcontent[-6 .. -1] -Path $newcontent
        #clean up tmp file and delete old file
        Move-Item $PSItem.FullName -Destination (Join-Path -Path $provinceloc -ChildPath 'Processed')
    }
}

function getprovinces {
	$provinceloc = "C:\Users\cbaumhart\Documents\GitHub\ck2-to-euiv-goon-judea\history\provinces"
    #$provinceloc = "C:\Program Files (x86)\Steam\steamapps\common\Europa Universalis IV\history\provinces"
    $nameloc = "C:\Program Files (x86)\Steam\steamapps\common\Europa Universalis IV\localisation\prov_names_l_english.yml"
    $namecontent = Get-Content $nameloc
    $provcontent = Get-ChildItem $provinceloc -File
    $worlddata = @()
    $provcontent | foreach {
        $provnum = $null
        $provname = $null

        $provowner = @()
        $discoveredby = @()
        $addcore = @()
        $provcontroller = @()
        $culture = @()
        $religion = @()
        $citysize = @()
        $basetax = @()
        $baseproduction = @()
        $basemanpower = @()
        $capital = @()
        $addlocalautonomy = @()
        $iscity = @()
        $tradegoods = @()
        
        $provdata = New-Object psobject
        $filecontent = get-content $PSItem.FullName
        #Get Province Number from file name
        if ($PSItem.name.chars(3) -match "[0-9]") {
            $ItemNumbers = 4
        }
        Elseif ($PSItem.name.chars(2) -match "[0-9]") {
            $ItemNumbers = 3
        }
        Elseif ($PSItem.name.chars(1) -match "[0-9]") {
            $ItemNumbers = 2
        } 
        Else {$ItemNumbers = 1}
        $provnum = $PSItem.Name.Substring(0,$ItemNumbers)
        #Get Province Name from English Localisation file
        $namecontent | foreach {
            if($_.tostring().substring(5,($provnum+":").Length) -eq ($provnum+":")){
                $provname = $_.ToString().TrimStart(" PROV"+$provnum+": ").TrimStart('"').trimEnd('"')
            } 
        }
        #Parse file, pulling important bits
        $filecontent | Foreach {
            if(!($_.ToString().StartsWith(1))){
                if($_.ToString() -match ("owner = ")){ 
                    $provowner += $_.ToString().Trim().TrimStart("owner ") -replace '= ','' 
                }
                if($_.ToString() -match ("controller = ")) { 
                    $provcontroller += $_.ToString().Trim().TrimStart("controller ") -replace '= ',''
                }
                if($_.ToString() -match ("add_core = ")) { 
                    $addcore += $_.ToString().Trim().TrimStart("add_core ") -replace '= ',''
                }
                if($_.ToString() -match ("culture = ")) { 
                    $culture += $_.ToString().Trim().TrimStart("culture ") -replace '= ',''
                }
                if($_.ToString() -match ("religion = ")) { 
                    $religion += $_.ToString().Trim().TrimStart("religion ") -replace '= ',''
                }
                if($_.ToString() -match ("citysize = ")) { 
                    $citysize += $_.ToString().Trim().TrimStart("citysize ") -replace '= ',''
                }
                if($_.ToString() -match ("discovered_by = ")) { 
                    $discoveredby += $_.ToString().Trim().TrimStart("discovered_by ") -replace '= ','' 
                }
                $hre = "no"
                if($_.ToString() -match ("base_tax = ")) { 
                    $basetax += $_.ToString().Trim().TrimStart("base_tax ") -replace '= ',''
                }
                if($_.ToString() -match ("base_production = ")) { 
                    $baseproduction += $_.ToString().Trim().TrimStart("base_production ") -replace '= ',''
                }
                if($_.ToString() -match ("base_manpower = ")) { 
                    $basemanpower += $_.ToString().Trim().TrimStart("base_manpower ") -replace '= ',''
                }
                if($_.ToString() -match ("capital = ")) { 
                    $capital += $_.ToString().Trim().TrimStart("capital ") -replace '= ',''
                }
                if($_.ToString() -match ("add_local_autonomy = ")) { 
                    $addlocalautonomy += $_.ToString().Trim().TrimStart("add_local_autonomy ") -replace '= ',''
                }
                if($_.ToString() -match ("is_city = ")) { 
                    $iscity += $_.ToString().Trim().TrimStart("is_city ") -replace '= ',''
                }
                if($_.ToString() -match ("trade_goods = ")) { 
                    $tradegoods += $_.ToString().Trim().TrimStart("trade_goods ") -replace '= ',''
                }
                <#Regex cheatsheet
                for a nation's tag  - [A-Z]{3}
                to exclude year lines - \d{4}
                
                

                #>

            }
        }
        #add it all up to a sandwich
        $provdata | add-member -MemberType Noteproperty -name Province_Number -Value ($provnum)
        $provdata | add-member -MemberType Noteproperty -name Province_Name -Value ($provname)
        $provdata | add-member -MemberType Noteproperty -name Owner -Value ($provowner[0])
        $provdata | add-member -MemberType Noteproperty -name Controller -Value ($provcontroller[0])
        $provdata | add-member -MemberType Noteproperty -name Add_Core -Value ($addcore -join ',')
        $provdata | add-member -MemberType Noteproperty -name Culture -Value ($culture[0])
        $provdata | add-member -MemberType Noteproperty -name Religion -Value ($religion[0])
        $provdata | add-member -MemberType Noteproperty -name CitySize -Value ($citysize[0])
        $provdata | add-member -MemberType Noteproperty -name Discovered_by -Value ($discoveredby -join ',')
        $provdata | add-member -MemberType Noteproperty -name HRE -Value ($hre)
        $provdata | add-member -MemberType Noteproperty -name Base_Tax -Value ($basetax[0])
        $provdata | add-member -MemberType Noteproperty -name Base_Production -Value ($baseproduction[0])
        $provdata | add-member -MemberType Noteproperty -name Base_Manpower -Value ($basemanpower[0])
        $provdata | add-member -MemberType Noteproperty -name Capital -Value ($capital[0].TrimStart('"').trimEnd('"'))
        $provdata | add-member -MemberType Noteproperty -name Add_Local_Autonomy -Value ($addlocalautonomy[0])
        $provdata | add-member -MemberType Noteproperty -name Is_City -Value ($iscity[0])
        $provdata | add-member -MemberType Noteproperty -name Trade_Goods -Value ($tradegoods[0])
        #Add it to everything
        $worlddata += $provdata
    }
    $worlddata | Export-Csv -Path 'C:\temp\euiv.txt' -Delimiter "`t" -Encoding BigEndianUnicode -NoTypeInformation 
}

function setprovinces{
    $provinceloc = "C:\Users\cbaumhart\Documents\GitHub\ck2-to-euiv-goon-judea\history\provinces"
    $seedfile = "C:\Users\cbaumhart\Documents\GitHub\ck2-to-euiv-goon-judea\provinces 2.txt"
    $countryfile = get-content C:\Users\cbaumhart\Documents\GitHub\ck2-to-euiv-goon-judea\Countries.txt | sort
    $countries = @()
    $countries = $countryfile | foreach { $_.substring(0,3)}
    $rivers = import-csv -Path C:\Users\cbaumhart\Documents\GitHub\ck2-to-euiv-goon-judea\Rivers.txt -Delimiter "`t"
    $seed = Import-Csv -Path $seedfile -Delimiter "`t" -Encoding BigEndianUnicode
    $seed | foreach {
        #Declare Nulls
        $seedProvNum = $null
        $seedProvName = $null
        $seedOwner = $null
        $seedController = $null
        $seedAddCores = $null
        $seedCulture = $null
        $seedReligion = $null
        $seedCitySize = $null
        $seedDiscoveredBys = $null
        $seedHRE = $null
        $seedFort15th = $null
        $seedBaseTax = $null
        $seedBaseProd = $null
        $seedBaseMan = $null
        $seedTradeGoods = $null
        $seedIsCity = $null
        $seedCapital = $null
        $seedLocalAut = $null
        $seedAddClaim = $null
        $seedCenterOfTrade = $null
        $seedNativeSize = $null
        $seedNativeFerocity = $null
        $seedNativeHostile = $null
        $seedestuary = $null
        #Get info from line
        $seedProvNum = $PSItem.Province_Number 
        $seedParadoxName = $PSItem.Paradox_Name
        $seedProvName = $PSItem.Province_Name 
        if($PSItem.owner -ne ""){$seedOwner = $PSItem.Owner }
        if($PSItem.controller -ne ""){$seedController = $PSItem.Controller }
        if($PSItem.add_core -ne ""){$seedAddCores = $PSItem.Add_Core }
        if($PSItem.culture -ne ""){$seedCulture = $PSItem.Culture }
        if($PSItem.religion -ne ""){$seedReligion = $PSItem.Religion }
        if($PSItem.citysize -ne ""){$seedCitySize = $PSItem.CitySize }
        if($PSItem.discovered_by -ne ""){$seedDiscoveredBys = $PSItem.Discovered_by }
        if($PSItem.HRE -ne ""){$seedHRE = $PSItem.HRE }
        if($PSItem.fort_15th -ne ""){$seedFort15th = $PSItem.fort_15th }
        if($PSItem.base_tax -ne ""){$seedBaseTax = $PSItem.Base_Tax }
        if($PSItem.base_production -ne ""){$seedBaseProd = $PSItem.Base_Production }
        if($PSItem.base_manpower -ne ""){$seedBaseMan = $PSItem.Base_Manpower }
        if($PSItem.trade_goods -ne ""){$seedTradeGoods = $PSItem.trade_goods }
        if($PSItem.is_city -ne ""){$seedIsCity = $PSItem.is_city }
        if($PSItem.capital -ne ""){$seedCapital = $PSItem.capital }
        if($PSItem.add_local_autonomy -ne ""){$seedLocalAut = $PSItem.add_local_autonomy }
        if($PSItem.add_claim -ne ""){$seedAddClaim = $PSItem.add_claim }
        if($PSItem.center_of_trade -ne ""){$seedCenterOfTrade = $PSItem.center_of_trade }
        if($PSItem.Native_Size -ne "N/A"){$seedNativeSize = $PSItem.Native_Size} #
        if($PSItem.Native_Ferocity -ne "N/A"){$seedNativeFerocity = $PSItem.Native_Ferocity} #
        if($PSItem.Native_Hostileness -ne "N/A"){$seedNativeHostile = $PSItem.Native_Hostileness} #

        #process name to sanitize weird unicode characters from file name so that Windows won't choke
        #$seedProvNameSafe = ($seedProvName -replace "š","s" -replace "'","" -replace " ","" -replace "Ö","O" -replace "ö","o" -replace "ä","a" -replace "æ","ae" -replace "ø","o" -replace "ü","u" -replace "è","e" -replace "É","E" -replace "ú","u" -replace "á","a" -replace "é","e" -replace "í","i" -replace "ó","o" -replace "Î","I" -replace "Å","A" -replace '"','' -replace "ñ","n" -replace "ç","c" ).trim()
        
        
        
        
        IF($seedProvNum -le 34){ #No space by dashes for first 34 provinces
            $seedProvinceFileName = [string]($seedProvNum+"-"+$seedParadoxName+".txt")#_conv.txt")
        }
        ELSE{
            $seedProvinceFileName = [string]($seedProvNum+" - "+$seedParadoxName+".txt")#_conv.txt")
        }
        Write-Host "Creating file for" $seedProvinceFileName

        $seedProvinceFile = New-Item -ItemType File -Name $seedProvinceFileName -Path $provinceloc
        #Start adding content
        Add-Content -Value ("#" + $seedProvName + " - generated from datasheet") -Path $seedProvinceFile

        if($seedOwner -ne $null){Add-Content -Value ("owner = " + $seedOwner) -Path $seedProvinceFile}
        if($seedController -ne $null){Add-Content -Value ("controller = " + $seedController) -Path $seedProvinceFile}
        if($seedaddcores -ne $null){
                $seedaddcore = $seedAddCores.Split(",")
                $seedaddcore | foreach { Add-Content -Value ("add_core = " + $_) -Path $seedProvinceFile }
            }
        if($seedCulture -ne $null){Add-Content -Value ("culture = " + $seedCulture) -Path $seedProvinceFile}
        if($seedReligion -ne $null){Add-Content -Value ("religion = " + $seedReligion) -Path $seedProvinceFile}
        if($seediscity -ne $null){Add-Content -Value ("is_city = " + $seedIsCity) -Path $seedProvinceFile}
        if($seedDiscoveredBys -ne $null){
            $seeddiscoveredby = $seedDiscoveredBys.split(",")
            $seeddiscoveredby | foreach { Add-Content -Value ("discovered_by = " + $_) -Path $seedProvinceFile }
        }
        if($seedBaseTax -ge 1){Add-Content -Value ("base_tax = " + $seedBaseTax) -Path $seedProvinceFile}
        if($seedBaseProd -ge 1){Add-Content -Value ("base_production = " + $seedBaseProd) -Path $seedProvinceFile}
        if($seedBaseMan -ge 1){Add-Content -Value ("base_manpower = " + $seedBaseMan) -Path $seedProvinceFile}
        if($seedCapital -ne $null){Add-Content -Value ('capital = "' + $seedCapital + '"') -Path $seedProvinceFile}
        if($seedAddClaim -ne $null){Add-Content -Value ('add_claim = "' + $seedAddClaim + '"') -Path $seedProvinceFile}
        if($seedFort15th -ne $null){Add-Content -value ('fort_15th = ' + $seedFort15th) -Path $seedProvinceFile}
        if($seedTradeGoods -ne $null){Add-Content -Value ("trade_goods = " + $seedTradeGoods) -Path $seedProvinceFile}
        if($seedLocalAut -ne $null){Add-Content -Value ("add_local_autonomy = " + $seedLocalAut) -Path $seedProvinceFile}
        if($seedNativeSize -ne $null){Add-Content -Value ("native_size = " + $seedNativeSize) -Path $seedProvinceFile}
        if($seedNativeFerocity -ne $null){Add-Content -Value ("native_ferocity = " + $seedNativeFerocity) -Path $seedProvinceFile}
        if($seedNativeHostile -ne $null){Add-Content -Value ("native_hostileness = " + $seedNativeHostile) -Path $seedProvinceFile}
        if($seedCenterOfTrade -eq 'yes'){
            Add-Content -Value 'add_permanent_province_modifier = {' -Path $seedProvinceFile
	        Add-Content -Value "`tname = center_of_trade_modifier" -Path $seedProvinceFile
	        Add-Content -Value "`tduration = -1" -Path $seedProvinceFile
            Add-Content -Value '}' -Path $seedProvinceFile
        }
        if($seedCenterOfTrade -eq 'inland'){
            Add-Content -Value 'add_permanent_province_modifier = {' -Path $seedProvinceFile
	        Add-Content -Value "`tname = inland_center_of_trade_modifier" -Path $seedProvinceFile
	        Add-Content -Value "`tduration = -1" -Path $seedProvinceFile
            Add-Content -Value '}' -Path $seedProvinceFile
        }
        if($seedCenterOfTrade -eq 'harbor'){
            Add-Content -Value 'add_permanent_province_modifier = {' -Path $seedProvinceFile
	        Add-Content -Value "`tname = important_natural_harbor" -Path $seedProvinceFile
	        Add-Content -Value "`tduration = -1" -Path $seedProvinceFile
            Add-Content -Value '}' -Path $seedProvinceFile
        }
        if($seedProvNum -eq 379){ #Add temple to Jerusalem
        Add-Content -Value 'add_building = temple' -Path $seedProvinceFile
        Add-Content -Value 'add_permanent_province_modifier = {' -Path $seedProvinceFile
	        Add-Content -Value "`tname = the_third_temple" -Path $seedProvinceFile
	        Add-Content -Value "`tduration = -1" -Path $seedProvinceFile
            Add-Content -Value '}' -Path $seedProvinceFile
        }
        #check for rivers
        if($rivers.province -contains $seedProvNum){
            $rivers | foreach {if($_.province -eq $seedProvNum){$seedestuary = $_.estuary}}
            Add-Content -Value "add_permanent_province_modifier = {" -path $seedProvinceFile
            Add-Content -Value ("`tname = "+$seedestuary+"_estuary_modifier") -Path $seedProvinceFile
	        Add-Content -Value "`tduration = -1" -Path $seedProvinceFile
            Add-Content -Value '}' -Path $seedProvinceFile
        }
        Add-Content -Value "1453.1.1 = {" -path $seedProvinceFile
        if($seedHRE -ne $null){Add-Content -Value ("`thre = " + $seedHRE) -Path $seedProvinceFile} 
        $countries | foreach {
            if(!($seedaddcore -contains $PSItem)){Add-Content -Value ("`tremove_core = " + $PSItem) -Path $seedProvinceFile}
        }
        Add-Content -value "}" -Path $seedProvinceFile
        #Write controller stuff again so that it doesn't break like every single time.
        Add-Content -value "1453.1.1 = {" -path $seedProvinceFile
        Add-Content -value ("`towner = " + $seedOwner) -Path $seedProvinceFile
        Add-Content -Value ("`tcontroller = " + $seedController) -Path $seedProvinceFile
        Add-Content -Value ("`tculture = " + $seedCulture) -Path $seedProvinceFile
        Add-Content -Value ("`treligion = " + $seedReligion) -Path $seedProvinceFile
        Add-Content -Value "}"  -Path $seedProvinceFile
        #Need a blank line at the end.
        Add-Content -Value "" -Path $seedProvinceFile
    }
}