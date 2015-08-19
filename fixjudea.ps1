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
    $nameloc = "C:\Program Files (x86)\Steam\steamapps\common\Europa Universalis IV\localisation\prov_names_l_english.yml"
    $namecontent = Get-Content $nameloc
    $provcontent = Get-ChildItem $provinceloc -File
    $worlddata = @()
    $provcontent | foreach {
        $provowner = $null
        $discoveredby = @()
        $addcore = @()
        $provcontroller = $null
        $culture = $null
        $religion = $null
        $citysize = $null
        $basetax = $null
        $baseproduction = $null
        $basemanpower = $null
        $provnum = $null
        $provname = $null
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
        if($_.ToString() -match ("owner = ")){ $provowner = $_.ToString().Trim().TrimStart("owner ") -replace '= ','' }
        if($_.ToString() -match ("controller = ")) { $provcontroller = $_.ToString().Trim().TrimStart("controller ") -replace '= ',''}
        if($_.ToString() -match ("add_core = ")) { $addcore += $_.ToString().Trim().TrimStart("add_core ") -replace '= ',''}
        if($_.ToString() -match ("culture = ")) { $culture = $_.ToString().Trim().TrimStart("culture ") -replace '= ',''}
        if($_.ToString() -match ("religion = ")) { $religion = $_.ToString().Trim().TrimStart("religion ") -replace '= ',''}
        if($_.ToString() -match ("citysize = ")) { $citysize = $_.ToString().Trim().TrimStart("citysize ") -replace '= ',''}
        if($_.ToString() -match ("discovered_by = ")) { $discoveredby += $_.ToString().Trim().TrimStart("discovered_by ") -replace '= ','' }
        $hre = "no"
        if($_.ToString() -match ("base_tax = ")) { $basetax = $_.ToString().Trim().TrimStart("base_tax ") -replace '= ',''}
        if($_.ToString() -match ("base_production = ")) { $baseproduction = $_.ToString().Trim().TrimStart("base_production ") -replace '= ',''}
        if($_.ToString() -match ("base_manpower = ")) { $basemanpower = $_.ToString().Trim().TrimStart("base_manpower ") -replace '= ',''}
        }
        #add it all up to a sandwich
        $provdata | add-member -MemberType Noteproperty -name Province_Number -Value ($provnum -join ',')
        $provdata | add-member -MemberType Noteproperty -name Province_Name -Value ($provname -join ',')
        $provdata | add-member -MemberType Noteproperty -name Owner -Value ($provowner -join ',')
        $provdata | add-member -MemberType Noteproperty -name Controller -Value ($provcontroller -join ',')
        $provdata | add-member -MemberType Noteproperty -name Add_Core -Value ($addcore -join ',')
        $provdata | add-member -MemberType Noteproperty -name Culture -Value ($culture -join ',')
        $provdata | add-member -MemberType Noteproperty -name Religion -Value ($religion -join ',')
        $provdata | add-member -MemberType Noteproperty -name CitySize -Value ($citysize -join ',')
        $provdata | add-member -MemberType Noteproperty -name Discovered_by -Value ($discoveredby -join ',')
        $provdata | add-member -MemberType Noteproperty -name HRE -Value ($hre -join ',')
        $provdata | add-member -MemberType Noteproperty -name Base_Tax -Value ($basetax -join ',')
        $provdata | add-member -MemberType Noteproperty -name Base_Production -Value ($baseproduction -join ',')
        $provdata | add-member -MemberType Noteproperty -name Base_Manpower -Value ($basemanpower -join ',')
        #Add it to everything
        $worlddata += $provdata
    }
    $worlddata | Export-Csv -Path 'C:\temp\euiv.txt' -Delimiter "`t" -Encoding BigEndianUnicode -NoTypeInformation 
}