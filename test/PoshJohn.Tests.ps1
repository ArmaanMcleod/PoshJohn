Describe 'PoshJohn Tests' {

    BeforeAll {
        $repoPath = (Get-Item -Path $PSScriptRoot).Parent.FullName
        $modulePath = Join-Path -Path $repoPath -ChildPath 'out' -AdditionalChildPath 'PoshJohn'
        Import-Module -Name $modulePath -Force

        $sampleProtectedPdfPath = Join-Path -Path $TestDrive -ChildPath 'SampleProtected.pdf'
        $sampleProtectedPdfHashPath = Join-Path -Path $TestDrive -ChildPath 'SampleProtectedHash.txt'
        $nonPasswordProtectedPdfPath = Join-Path -Path $TestDrive -ChildPath 'NoPassword.pdf'
        $sampleProtectedZipPath = Join-Path -Path $TestDrive -ChildPath 'ProtectedArchive.zip'
        $sampleProtectedZipHashPath = Join-Path -Path $TestDrive -ChildPath 'ProtectedArchiveHash.txt'

        $sampleProtectedZipFiles = @(
            (Join-Path -Path $TestDrive -ChildPath 'File1.txt'),
            (Join-Path -Path $TestDrive -ChildPath 'File2.txt')
        )

        $sampleProtectedZipFiles | ForEach-Object {
            Set-Content -Path $_ -Value "This is a test file."
        }

        $samplePDFPassword = "test123"
        $sampleZIPPassword = "test123"
    }

    Context 'Export-JohnPasswordHash' {

        It 'Should export PDF passwords to John the Ripper format' -Tag 'export-hash', 'pdf' {
            [PoshJohn.TestUtils.FileHelpers]::CreateSamplePasswordProtectedPDF($sampleProtectedPdfPath, $samplePDFPassword, "RC4-40")
            $output = Export-JohnPasswordHash -InputPath $sampleProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath
            $output | Should -BeOfType [PoshJohn.Models.HashResult]
            $output.HashFilePath | Should -Be $sampleProtectedPdfHashPath
            Test-Path $sampleProtectedPdfHashPath | Should -BeTrue

            $hashLine = Get-Content -Path $sampleProtectedPdfHashPath
            $hashLine | Should -HaveCount 1
            $splitHash = $hashLine.Split(':')
            $splitHash | Should -HaveCount 2
            $base64Path = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($sampleProtectedPdfPath))
            $splitHash[0] | Should -Be $base64Path
            $splitHash[1] | Should -Match '^\$pdf\$'
            $splitHash[1] | Should -Be $output.Hash
        }

        It 'Should append PDF passwords to John the Ripper format' -Tag 'export-hash', 'pdf' {

            for ($i = 1; $i -le 2; $i++) {
                $pdfPath = Join-Path -Path $TestDrive -ChildPath "SampleProtected$i.pdf"
                $password = "test$i"
                [PoshJohn.TestUtils.FileHelpers]::CreateSamplePasswordProtectedPDF($pdfPath, $password, "RC4-40")
                $output = Export-JohnPasswordHash -InputPath $pdfPath -OutputPath $sampleProtectedPdfHashPath -Append
                $output | Should -BeOfType [PoshJohn.Models.HashResult]
                $output.HashFilePath | Should -Be $sampleProtectedPdfHashPath
                Test-Path $sampleProtectedPdfHashPath | Should -BeTrue

                $hashLines = @(Get-Content -Path $sampleProtectedPdfHashPath)
                $hashLines | Should -HaveCount $i
                $splitHash = $hashLines[$i - 1].Split(':')
                $splitHash | Should -HaveCount 2
                $base64Path = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($pdfPath))
                $splitHash[0] | Should -Be $base64Path
                $splitHash[1] | Should -Match '^\$pdf\$'
                $splitHash[1] | Should -Be $output.Hash
            }
        }

        It 'Should export ZIP passwords to John the Ripper format' -Tag 'export-hash', 'zip' {
            [PoshJohn.TestUtils.FileHelpers]::CreatePasswordProtectedZip($sampleProtectedZipPath, $sampleProtectedZipFiles, $sampleZIPPassword)
            $output = Export-JohnPasswordHash -InputPath $sampleProtectedZipPath -OutputPath $sampleProtectedZipHashPath
            $output | Should -BeOfType [PoshJohn.Models.HashResult]
            $output.HashFilePath | Should -Be $sampleProtectedZipHashPath
            Test-Path $sampleProtectedZipHashPath | Should -BeTrue

            $hashLine = Get-Content -Path $sampleProtectedZipHashPath
            $hashLine | Should -HaveCount 1

            $splitHash = $hashLine.Split('::')

            $firstPart = $splitHash[0].Split(':')
            $firstPart | Should -HaveCount 2
            $firstPart[0] | Should -Be (Split-Path -Path $sampleProtectedZipPath -Leaf)
            $firstPart[1] | Should -Match '^\$(pkzip|pkzip2)\$.*\$/pkzip(2)?\$$'

            $secondPart = $splitHash[1].Split(':', 3)
            $secondPart | Should -HaveCount 3
            $secondPart[0] | Should -Be (Split-Path -Path $sampleProtectedZipPath -Leaf)
            $secondPart[1] | Should -Be ($sampleProtectedZipFiles | ForEach-Object { Split-Path -Path $_ -Leaf } | Sort-Object | Join-String -Separator ', ')
            $secondPart[2] | Should -Be $sampleProtectedZipPath
        }

        It 'Should throw error for non-existent input file' -Tag 'export-hash' {
            $nonExistentPath = Join-Path -Path $TestDrive -ChildPath 'NonExistent.pdf'
            { Export-JohnPasswordHash -InputPath $nonExistentPath -OutputPath $sampleProtectedPdfHashPath } | Should -Throw -ExceptionType 'System.IO.FileNotFoundException'
        }

        It 'Should throw error when trying to crack non-password-protected PDF file' -Tag 'export-hash' {
            [PoshJohn.TestUtils.FileHelpers]::CreatePDFWithNoPassword($nonPasswordProtectedPdfPath)
            { Export-JohnPasswordHash -InputPath $nonPasswordProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath } | Should -Throw -ExceptionType 'System.InvalidOperationException'
        }

        It 'Should throw error for unsupported file format' -Tag 'export-hash' {
            $unsupportedFilePath = Join-Path -Path $TestDrive -ChildPath 'Unsupported.txt'
            Set-Content -Path $unsupportedFilePath -Value "This is a test file."
            { Export-JohnPasswordHash -InputPath $unsupportedFilePath -OutputPath $sampleProtectedPdfHashPath } | Should -Throw -ExceptionType 'System.IO.InvalidDataException'
        }

        AfterEach {
            Remove-Item -Path $sampleProtectedPdfPath -ErrorAction SilentlyContinue
            Remove-Item -Path $sampleProtectedPdfHashPath -ErrorAction SilentlyContinue

            for ($i = 1; $i -le 2; $i++) {
                $pdfPath = Join-Path -Path $TestDrive -ChildPath "SampleProtected$i.pdf"
                Remove-Item -Path $pdfPath -ErrorAction SilentlyContinue
            }

            Remove-Item -Path $sampleProtectedZipPath -ErrorAction SilentlyContinue
            Remove-Item -Path $sampleProtectedZipHashPath -ErrorAction SilentlyContinue
        }

        AfterAll {
            Remove-Item -Path $nonPasswordProtectedPdfPath -ErrorAction SilentlyContinue
        }
    }

    Context 'Invoke-JohnPasswordCrack' {

        Context 'Incremental Mode' {

            Context 'Using John the Ripper to crack PDF password hashes on individual PDF files using brute-force' {

                BeforeEach {
                    [PoshJohn.TestUtils.FileHelpers]::CreateSamplePasswordProtectedPDF($sampleProtectedPdfPath, $samplePDFPassword, "RC4-40")
                }

                It 'Should crack password hashes using John the Ripper using default incremental mode' -Tag 'pipeline-input' {
                    Export-JohnPasswordHash -InputPath $sampleProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath

                    $crackResult = Invoke-JohnPasswordCrack -InputPath $sampleProtectedPdfHashPath
                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.RawOutput | Should -Match $samplePDFPassword

                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PDF'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -BeIn @('MD5 SHA2 RC4/AES 32/64', 'MD5-RC4 / SHA2-AES 32/64')
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password | Should -Be $samplePDFPassword
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FilePath | Should -Be $sampleProtectedPdfPath
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FileFormat | Should -Be 'PDF'

                    $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password
                    $crackedPassword | Should -Be $samplePDFPassword
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($sampleProtectedPdfPath, $crackedPassword) | Should -BeTrue

                    $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].UnlockedFilePath
                    $unlockedFilePath.Replace("_unlocked", "") | Should -Be $sampleProtectedPdfPath
                    Test-Path -Path $unlockedFilePath | Should -BeTrue
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($unlockedFilePath) | Should -BeTrue
                }

                It 'Should crack password hashes using John the Ripper using default incremental mode and pipeline input' -Tag 'pipeline-input' {
                    $crackResult = Export-JohnPasswordHash -InputPath $sampleProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath | Invoke-JohnPasswordCrack
                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.RawOutput | Should -Match $samplePDFPassword

                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PDF'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -BeIn @('MD5 SHA2 RC4/AES 32/64', 'MD5-RC4 / SHA2-AES 32/64')
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password | Should -Be $samplePDFPassword
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FilePath | Should -Be $sampleProtectedPdfPath
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FileFormat | Should -Be 'PDF'

                    $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password
                    $crackedPassword | Should -Be $samplePDFPassword
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($sampleProtectedPdfPath, $crackedPassword) | Should -BeTrue

                    $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].UnlockedFilePath
                    $unlockedFilePath.Replace("_unlocked", "") | Should -Be $sampleProtectedPdfPath
                    Test-Path -Path $unlockedFilePath | Should -BeTrue
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($unlockedFilePath) | Should -BeTrue
                }

                It "Should crack password hashes using specific incremental mode '<IncrementalMode>'" -TestCases @(
                    @{ IncrementalMode = 'digits'; Password = '123456' }
                    @{ IncrementalMode = 'lower'; Password = 'password' }
                    @{ IncrementalMode = 'upper'; Password = 'PASSWORD' }
                    @{ IncrementalMode = 'alpha'; Password = 'aB' }
                    @{ IncrementalMode = 'alnum'; Password = 'aB1' }
                ) {
                    param($IncrementalMode, $Password)
                    [PoshJohn.TestUtils.FileHelpers]::CreateSamplePasswordProtectedPDF($sampleProtectedPdfPath, $Password, "RC4-40")
                    Export-JohnPasswordHash -InputPath $sampleProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath
                    $crackResult = Invoke-JohnPasswordCrack -InputPath $sampleProtectedPdfHashPath -IncrementalMode $IncrementalMode
                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.RawOutput | Should -Match $Password

                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PDF'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -BeIn @('MD5 SHA2 RC4/AES 32/64', 'MD5-RC4 / SHA2-AES 32/64')
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password | Should -Be $Password
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FilePath | Should -Be $sampleProtectedPdfPath
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FileFormat | Should -Be 'PDF'

                    $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password
                    $crackedPassword | Should -Be $Password
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($sampleProtectedPdfPath, $crackedPassword) | Should -BeTrue

                    $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].UnlockedFilePath
                    $unlockedFilePath.Replace("_unlocked", "") | Should -Be $sampleProtectedPdfPath
                    Test-Path -Path $unlockedFilePath | Should -BeTrue
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($unlockedFilePath) | Should -BeTrue
                }

                AfterEach {
                    Remove-Item -Path $sampleProtectedPdfPath -ErrorAction SilentlyContinue
                    Remove-Item -Path $sampleProtectedPdfHashPath -ErrorAction SilentlyContinue
                }
            }

            Context 'Using John the Ripper to crack PDF password using the same PDF file using brute-force' {

                BeforeAll {
                    [PoshJohn.TestUtils.FileHelpers]::CreateSamplePasswordProtectedPDF($sampleProtectedPdfPath, "test123", "RC4-40")
                }

                It 'Should crack password hashes using John the Ripper using default incremental mode' -Tag 'pot-file' {
                    Export-JohnPasswordHash -InputPath $sampleProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath

                    $crackResult = Invoke-JohnPasswordCrack -InputPath $sampleProtectedPdfHashPath
                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.RawOutput | Should -Match $samplePDFPassword

                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PDF'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -BeIn @('MD5 SHA2 RC4/AES 32/64', 'MD5-RC4 / SHA2-AES 32/64')
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password | Should -Be $samplePDFPassword
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FilePath | Should -Be $sampleProtectedPdfPath
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FileFormat | Should -Be 'PDF'

                    $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password
                    $crackedPassword | Should -Be $samplePDFPassword
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($sampleProtectedPdfPath, $crackedPassword) | Should -BeTrue

                    $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].UnlockedFilePath
                    $unlockedFilePath.Replace("_unlocked", "") | Should -Be $sampleProtectedPdfPath
                    Test-Path -Path $unlockedFilePath | Should -BeTrue
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($unlockedFilePath) | Should -BeTrue
                }

                It 'Should crack password hashes using John the Ripper using default incremental mode when hash already in pot file' -Tag 'pot-file' {
                    Export-JohnPasswordHash -InputPath $sampleProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath

                    $crackResult = Invoke-JohnPasswordCrack -InputPath $sampleProtectedPdfHashPath
                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.RawOutput | Should -Not -Match $samplePDFPassword

                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PDF'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -BeIn @('MD5 SHA2 RC4/AES 32/64', 'MD5-RC4 / SHA2-AES 32/64')
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password | Should -Be $samplePDFPassword
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FilePath | Should -Be $sampleProtectedPdfPath
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FileFormat | Should -Be 'PDF'

                    $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password
                    $crackedPassword | Should -Be $samplePDFPassword
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($sampleProtectedPdfPath, $crackedPassword) | Should -BeTrue

                    $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].UnlockedFilePath
                    $unlockedFilePath.Replace("_unlocked", "") | Should -Be $sampleProtectedPdfPath
                    Test-Path -Path $unlockedFilePath | Should -BeTrue
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($unlockedFilePath) | Should -BeTrue
                }

                It 'Should crack password hashes using John the Ripper using default incremental mode and refreshed pot file' -Tag 'pot-file' {
                    Export-JohnPasswordHash -InputPath $sampleProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath

                    $crackResult = Invoke-JohnPasswordCrack -InputPath $sampleProtectedPdfHashPath -RefreshPot -WarningVariable warnings
                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.RawOutput | Should -Match $samplePDFPassword

                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PDF'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -BeIn @('MD5 SHA2 RC4/AES 32/64', 'MD5-RC4 / SHA2-AES 32/64')
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password | Should -Be $samplePDFPassword
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FilePath | Should -Be $sampleProtectedPdfPath
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FileFormat | Should -Be 'PDF'

                    $warnings | Should -Not -BeNullOrEmpty
                    $warnings | Should -HaveCount 1
                    $warnings[0] | Should -Be "Refreshing pot file: $($crackResult.PotPath)"

                    $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password
                    $crackedPassword | Should -Be $samplePDFPassword
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($sampleProtectedPdfPath, $crackedPassword) | Should -BeTrue

                    $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].UnlockedFilePath
                    $unlockedFilePath.Replace("_unlocked", "") | Should -Be $sampleProtectedPdfPath
                    Test-Path -Path $unlockedFilePath | Should -BeTrue
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($unlockedFilePath) | Should -BeTrue
                }

                AfterEach {
                    Remove-Item -Path $sampleProtectedPdfHashPath -ErrorAction SilentlyContinue
                }

                AfterAll {
                    Remove-Item -Path $sampleProtectedPdfPath -ErrorAction SilentlyContinue
                }
            }

            Context 'Using John the Ripper to crack PDF password using custom pot path' {
                BeforeAll {
                    $customPotPath = Join-Path -Path $TestDrive -ChildPath 'custom-pot-file.pot'
                }

                It 'Should crack password hashes using John the Ripper using default incremental mode and custom pot path' {
                    [PoshJohn.TestUtils.FileHelpers]::CreateSamplePasswordProtectedPDF($sampleProtectedPdfPath, $samplePDFPassword, "RC4-40")

                    Export-JohnPasswordHash -InputPath $sampleProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath

                    $crackResult = Invoke-JohnPasswordCrack -InputPath $sampleProtectedPdfHashPath -CustomPotPath $customPotPath
                    Test-Path $customPotPath | Should -BeTrue
                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.RawOutput | Should -Match $samplePDFPassword

                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PDF'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -BeIn @('MD5 SHA2 RC4/AES 32/64', 'MD5-RC4 / SHA2-AES 32/64')
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password | Should -Be $samplePDFPassword
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FilePath | Should -Be $sampleProtectedPdfPath
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FileFormat | Should -Be 'PDF'
                    $crackResult.PotPath | Should -Be $customPotPath

                    $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password
                    $crackedPassword | Should -Be $samplePDFPassword
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($sampleProtectedPdfPath, $crackedPassword) | Should -BeTrue

                    $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].UnlockedFilePath
                    $unlockedFilePath.Replace("_unlocked", "") | Should -Be $sampleProtectedPdfPath
                    Test-Path -Path $unlockedFilePath | Should -BeTrue
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($unlockedFilePath) | Should -BeTrue
                }

                It 'Should crack password hashes using John the Ripper using default incremental mode and refreshed custom pot path' {
                    [PoshJohn.TestUtils.FileHelpers]::CreateSamplePasswordProtectedPDF($sampleProtectedPdfPath, $samplePDFPassword, "RC4-40")

                    Export-JohnPasswordHash -InputPath $sampleProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath
                    $crackResult = Invoke-JohnPasswordCrack -InputPath $sampleProtectedPdfHashPath -CustomPotPath $customPotPath -RefreshPot -WarningVariable warnings
                    Test-Path $customPotPath | Should -BeTrue

                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.RawOutput | Should -Match $samplePDFPassword
                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PDF'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -BeIn @('MD5 SHA2 RC4/AES 32/64', 'MD5-RC4 / SHA2-AES 32/64')
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password | Should -Be $samplePDFPassword
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FilePath | Should -Be $sampleProtectedPdfPath
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FileFormat | Should -Be 'PDF'

                    $crackResult.PotPath | Should -Be $customPotPath
                    $warnings | Should -Not -BeNullOrEmpty
                    $warnings | Should -HaveCount 1
                    $warnings[0] | Should -Be "Refreshing pot file: $($crackResult.PotPath)"

                    $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password
                    $crackedPassword | Should -Be $samplePDFPassword
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($sampleProtectedPdfPath, $crackedPassword) | Should -BeTrue

                    $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].UnlockedFilePath
                    $unlockedFilePath.Replace("_unlocked", "") | Should -Be $sampleProtectedPdfPath
                    Test-Path -Path $unlockedFilePath | Should -BeTrue
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($unlockedFilePath) | Should -BeTrue
                }

                AfterEach {
                    Remove-Item -Path $sampleProtectedPdfPath -ErrorAction SilentlyContinue
                    Remove-Item -Path $sampleProtectedPdfHashPath -ErrorAction SilentlyContinue
                }
            }

            Context 'Using John the Ripper to crack multiple PDF password hashes from same hash file' {

                BeforeAll {
                    $combinedHashPath = Join-Path -Path $TestDrive -ChildPath 'CombinedPDFHashes.txt'
                }

                It 'Should crack multiple appended PDF password hashes' -Tag 'multi-pdf' {

                    for ($i = 1; $i -le 3; $i++) {
                        $pdfPath = Join-Path -Path $TestDrive -ChildPath "SampleProtected$i.pdf"
                        $password = "test$i"
                        [PoshJohn.TestUtils.FileHelpers]::CreateSamplePasswordProtectedPDF($pdfPath, $password, "RC4-40")
                        Export-JohnPasswordHash -InputPath $pdfPath -OutputPath $combinedHashPath -Append
                    }

                    $crackResult = Invoke-JohnPasswordCrack -InputPath $combinedHashPath
                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 3
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 3
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PDF'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -BeIn @('MD5 SHA2 RC4/AES 32/64', 'MD5-RC4 / SHA2-AES 32/64')
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 3

                    for ($i = 1; $i -le 3; $i++) {
                        $password = "test$i"
                        $crackResult.RawOutput | Should -Match $password
                        $pdfPath = Join-Path -Path $TestDrive -ChildPath "SampleProtected$i.pdf"

                        $crackResult.Summary.FormatGroups[0].FilePasswords[$pdfPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                        $crackResult.Summary.FormatGroups[0].FilePasswords[$pdfPath].Password | Should -Be $password
                        $crackResult.Summary.FormatGroups[0].FilePasswords[$pdfPath].FilePath | Should -Be $pdfPath
                        $crackResult.Summary.FormatGroups[0].FilePasswords[$pdfPath].FileFormat | Should -Be 'PDF'

                        $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$pdfPath].Password
                        $crackedPassword | Should -Be $password
                        [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($pdfPath, $crackedPassword) | Should -BeTrue

                        $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$pdfPath].UnlockedFilePath
                        $unlockedFilePath.Replace("_unlocked", "") | Should -Be $pdfPath
                        Test-Path -Path $unlockedFilePath | Should -BeTrue
                        [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($unlockedFilePath) | Should -BeTrue
                    }
                }

                AfterAll {
                    for ($i = 1; $i -le 3; $i++) {
                        $pdfPath = Join-Path -Path $TestDrive -ChildPath "SampleProtected$i.pdf"
                        Remove-Item -Path $pdfPath -ErrorAction SilentlyContinue
                    }
                    Remove-Item -Path $combinedHashPath -ErrorAction SilentlyContinue
                }
            }

            Context 'Output unlocked files to custom directory' {
                BeforeAll {
                    $unlockedOutputDir = Join-Path -Path $TestDrive -ChildPath 'UnlockedFiles'
                }

                It 'Should output unlocked files to custom directory' -Tag 'unlocked-dir' {
                    [PoshJohn.TestUtils.FileHelpers]::CreateSamplePasswordProtectedPDF($sampleProtectedPdfPath, $samplePDFPassword, "RC4-40")

                    Export-JohnPasswordHash -InputPath $sampleProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath

                    $crackResult = Invoke-JohnPasswordCrack -InputPath $sampleProtectedPdfHashPath -UnlockedFileDirectoryPath $unlockedOutputDir
                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.RawOutput | Should -Match $samplePDFPassword

                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PDF'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -BeIn @('MD5 SHA2 RC4/AES 32/64', 'MD5-RC4 / SHA2-AES 32/64')
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password | Should -Be $samplePDFPassword
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FilePath | Should -Be $sampleProtectedPdfPath
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FileFormat | Should -Be 'PDF'

                    $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password
                    $crackedPassword | Should -Be $samplePDFPassword
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($sampleProtectedPdfPath, $crackedPassword) | Should -BeTrue

                    $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].UnlockedFilePath
                    $unlockedFilePath | Should -Be (Join-Path -Path $unlockedOutputDir -ChildPath (Split-Path -Path $sampleProtectedPdfPath -Leaf).Replace('.pdf', '_unlocked.pdf'))
                    Test-Path -Path $unlockedFilePath | Should -BeTrue
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($unlockedFilePath) | Should -BeTrue
                }

                AfterEach {
                    Remove-Item -Path $sampleProtectedPdfPath -ErrorAction SilentlyContinue
                    Remove-Item -Path $sampleProtectedPdfHashPath -ErrorAction SilentlyContinue
                    Remove-Item -Path "$unlockedOutputDir/*" -ErrorAction SilentlyContinue
                }

                AfterAll {
                    Remove-Item -Path $unlockedOutputDir -ErrorAction SilentlyContinue
                }
            }

            Context 'Using John the Ripper to crack ZIP password hashes' {

                It 'Should crack ZIP password hashes using John the Ripper with incremental mode' -Tag 'zip-crack' {
                    [PoshJohn.TestUtils.FileHelpers]::CreatePasswordProtectedZip($sampleProtectedZipPath, $sampleProtectedZipFiles, $sampleZIPPassword)
                    Export-JohnPasswordHash -InputPath $sampleProtectedZipPath -OutputPath $sampleProtectedZipHashPath

                    $crackResult = Invoke-JohnPasswordCrack -InputPath $sampleProtectedZipHashPath
                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.RawOutput | Should -Match $sampleZIPPassword

                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PKZIP'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -Be '32/64'
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].Password | Should -Be $sampleZIPPassword
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].FilePath | Should -Be $sampleProtectedZipPath
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].FileFormat | Should -Be 'PKZIP'

                    $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].Password
                    $crackedPassword | Should -Be $sampleZIPPassword
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenZip($sampleProtectedZipPath, $crackedPassword) | Should -BeTrue

                    $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].UnlockedFilePath
                    $unlockedFilePath.Replace("_unlocked", "") | Should -Be $sampleProtectedZipPath
                    Test-Path -Path $unlockedFilePath | Should -BeTrue
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenZip($unlockedFilePath) | Should -BeTrue
                }

                It 'Should crack ZIP password hashes using John the Ripper with incremental mode and pipeline input' -Tag 'zip-crack' {
                    [PoshJohn.TestUtils.FileHelpers]::CreatePasswordProtectedZip($sampleProtectedZipPath, $sampleProtectedZipFiles, $sampleZIPPassword)
                    $crackResult = Export-JohnPasswordHash -InputPath $sampleProtectedZipPath -OutputPath $sampleProtectedZipHashPath | Invoke-JohnPasswordCrack
                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.RawOutput | Should -Match $sampleZIPPassword

                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PKZIP'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -Be '32/64'
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].Password | Should -Be $sampleZIPPassword
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].FilePath | Should -Be $sampleProtectedZipPath
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].FileFormat | Should -Be 'PKZIP'

                    $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].Password
                    $crackedPassword | Should -Be $sampleZIPPassword
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenZip($sampleProtectedZipPath, $crackedPassword) | Should -BeTrue

                    $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].UnlockedFilePath
                    $unlockedFilePath.Replace("_unlocked", "") | Should -Be $sampleProtectedZipPath
                    Test-Path -Path $unlockedFilePath | Should -BeTrue
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenZip($unlockedFilePath) | Should -BeTrue
                }

                It 'Should crack ZIP password hashes using John the Ripper with specific incremental mode when hash already in pot file' -Tag 'zip-crack' {
                    $crackResult = Export-JohnPasswordHash -InputPath $sampleProtectedZipPath -OutputPath $sampleProtectedZipHashPath | Invoke-JohnPasswordCrack
                    $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                    $crackResult.RawOutput | Should -Not -Match $sampleZIPPassword

                    $crackResult.Summary.FormatGroups | Should -HaveCount 1
                    $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                    $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PKZIP'
                    $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -Be '32/64'
                    $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].Password | Should -Be $sampleZIPPassword
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].FilePath | Should -Be $sampleProtectedZipPath
                    $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].FileFormat | Should -Be 'PKZIP'

                    $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].Password
                    $crackedPassword | Should -Be $sampleZIPPassword
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenZip($sampleProtectedZipPath, $crackedPassword) | Should -BeTrue

                    $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedZipPath].UnlockedFilePath
                    $unlockedFilePath.Replace("_unlocked", "") | Should -Be $sampleProtectedZipPath
                    Test-Path -Path $unlockedFilePath | Should -BeTrue
                    [PoshJohn.TestUtils.FileHelpers]::CanOpenZip($unlockedFilePath) | Should -BeTrue
                }

                AfterAll {
                    Remove-Item -Path $sampleProtectedZipPath -ErrorAction SilentlyContinue
                    Remove-Item -Path $sampleProtectedZipHashPath -ErrorAction SilentlyContinue
                }
            }
        }

        Context 'WordList Mode' {

            BeforeAll {
                $wordListPath = Join-Path -Path $TestDrive -ChildPath 'common-passwords.txt'
            }

            It 'Should crack password hashes using John the Ripper with a wordlist which contains the password' {
                [PoshJohn.TestUtils.FileHelpers]::CreateSamplePasswordProtectedPDF($sampleProtectedPdfPath, $samplePDFPassword, "RC4-40")

                @($samplePDFPassword, 'password2') | Set-Content -Path $wordListPath
                Export-JohnPasswordHash -InputPath $sampleProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath
                $crackResult = Invoke-JohnPasswordCrack -InputPath $sampleProtectedPdfHashPath -WordListPath $wordListPath
                $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                $crackResult.RawOutput | Should -Match $samplePDFPassword

                $crackResult.Summary.FormatGroups | Should -HaveCount 1
                $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PDF'
                $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -BeIn @('MD5 SHA2 RC4/AES 32/64', 'MD5-RC4 / SHA2-AES 32/64')
                $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 1

                $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath] | Should -BeOfType [PoshJohn.Models.PasswordUnlockResult]
                $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password | Should -Be $samplePDFPassword
                $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FilePath | Should -Be $sampleProtectedPdfPath
                $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].FileFormat | Should -Be 'PDF'

                $crackedPassword = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].Password
                $crackedPassword | Should -Be $samplePDFPassword
                [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($sampleProtectedPdfPath, $crackedPassword) | Should -BeTrue

                $unlockedFilePath = $crackResult.Summary.FormatGroups[0].FilePasswords[$sampleProtectedPdfPath].UnlockedFilePath
                $unlockedFilePath.Replace("_unlocked", "") | Should -Be $sampleProtectedPdfPath
                Test-Path -Path $unlockedFilePath | Should -BeTrue
                [PoshJohn.TestUtils.FileHelpers]::CanOpenPdf($unlockedFilePath) | Should -BeTrue
            }

            It 'Should not crack password hashes using John the Ripper with a wordlist which doesn''t contain the password' {
                [PoshJohn.TestUtils.FileHelpers]::CreateSamplePasswordProtectedPDF($sampleProtectedPdfPath, $samplePDFPassword, "RC4-40")

                @('password1', 'password2') | Set-Content -Path $wordListPath
                Export-JohnPasswordHash -InputPath $sampleProtectedPdfPath -OutputPath $sampleProtectedPdfHashPath
                $crackResult = Invoke-JohnPasswordCrack -InputPath $sampleProtectedPdfHashPath -WordListPath $wordListPath
                $crackResult | Should -BeOfType [PoshJohn.Models.PasswordCrackResult]
                $crackResult.RawOutput | Should -Not -Match $samplePDFPassword

                $crackResult.Summary.FormatGroups | Should -HaveCount 1
                $crackResult.Summary.FormatGroups[0].PasswordHashCount | Should -Be 1
                $crackResult.Summary.FormatGroups[0].SaltsCount | Should -Be 1
                $crackResult.Summary.FormatGroups[0].FileFormat | Should -Be 'PDF'
                $crackResult.Summary.FormatGroups[0].EncryptionAlgorithms | Should -BeIn @('MD5 SHA2 RC4/AES 32/64', 'MD5-RC4 / SHA2-AES 32/64')
                $crackResult.Summary.FormatGroups[0].FilePasswords.Count | Should -Be 0
            }

            AfterEach {
                Remove-Item -Path $sampleProtectedPdfPath -ErrorAction SilentlyContinue
                Remove-Item -Path $sampleProtectedPdfHashPath -ErrorAction SilentlyContinue
                Remove-Item -Path $wordListPath -ErrorAction SilentlyContinue
            }
        }

        Context 'Pdf2john Hash Tests' {
            BeforeAll {
                $venvPath = Join-Path -Path $TestDrive -ChildPath 'venv'
                if ($IsWindows) {
                    $pythonExe = "python.exe"
                    $venvPythonExe = Join-Path -Path $venvPath -ChildPath "Scripts\$pythonExe"
                    $pdf2JohnExe = "pdf2john.exe"
                }
                else {
                    $pythonExe = "python3"
                    $venvPythonExe = Join-Path -Path $venvPath -ChildPath "bin/$pythonExe"
                    $pdf2JohnExe = "pdf2john"
                }

                & $pythonExe -m venv $venvPath
                & $venvPythonExe -m pip install --upgrade pip
                & $venvPythonExe -m pip install pyhanko

                $pythonScriptPath = Get-ChildItem -Path $modulePath -Recurse -Filter 'pdf2john.py' | Select-Object -First 1 -ExpandProperty FullName
                $exePath = Get-ChildItem -Path $modulePath -Recurse -Filter $pdf2JohnExe | Select-Object -First 1 -ExpandProperty FullName

                if (-not $pythonScriptPath) {
                    throw "pdf2john.py not found in module path: $modulePath"
                }

                if (-not $exePath) {
                    throw "$pdf2JohnExe not found in module path: $modulePath. Did you build the project?"
                }
            }

            It "Should generate same pdf2john hash for Python and C pdfhash library using '<Algorithm>' encryption" -TestCases @(
                @{ Algorithm = "RC4-40" },
                @{ Algorithm = "RC4-128" },
                @{ Algorithm = "AES-128" },
                @{ Algorithm = "AES-256" }
            ) -Tag 'pdf2john-hash' {
                param($Algorithm)

                $samplePdfPath = Join-Path -Path $TestDrive -ChildPath "SampleProtected_$Algorithm.pdf"
                [PoshJohn.TestUtils.FileHelpers]::CreateSamplePasswordProtectedPDF($samplePdfPath, $samplePDFPassword, $Algorithm)

                [PoshJohn.TestUtils.FileHelpers]::GetPasswordProtectedPDFEncryptionType($samplePdfPath, $samplePDFPassword) | Should -Be $Algorithm

                $pythonHash = & $venvPythonExe $pythonScriptPath $samplePdfPath
                $exeHash = & $exePath $samplePdfPath

                $exeHash | Should -Be $pythonHash

                if ($IsLinux) {
                    $valgrindOutput = valgrind --leak-check=full --error-exitcode=1 $exePath $samplePdfPath 2>&1 | Out-String
                    $LASTEXITCODE | Should -Be 0 -Because "Valgrind should not detect memory errors"
                    $valgrindOutput | Should -Match "no leaks are possible|All heap blocks were freed" -Because "Valgrind output: $valgrindOutput"
                }
            }

            AfterAll {
                Remove-Item -Path "$TestDrive/SampleProtected_*.pdf" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path $venvPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
