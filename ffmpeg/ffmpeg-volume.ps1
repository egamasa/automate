# encoding: utf-8

#=== ffmpeg 一括音量調整スクリプト
#=== for PowerShell 7.0 or later

# スレッド数上限設定 (論理コア数 - 1)
$cpuCores = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
$maxParallelJobs = $cpuCores - 1

# カレントディレクトリ内の m4a ファイルをすべて取得
$files = Get-ChildItem -Path "." -Filter "*.m4a"
Write-Host "Files count: $($files.Count)"

# 変換処理 (ファイル毎)
$scriptBlock = {
    param($file)

    try {
        Write-Host "Start: $($file.Name)"

        $outputFileName = $file.FullName + "_output.m4a"

        # TODO: ffmpegコマンドのパラメータを変数に切り出す
        $ffmpegCommand = "ffmpeg -y -v error -i `"$($file.FullName)`" -af `"volume=3.0`" `"$outputFileName`""
        Invoke-Expression -Command $ffmpegCommand

        Write-Host "End: $($file.Name)"
    }
    catch {
        Write-Error "Error processing $($file.FullName): $_"
    }
}

# ジョブ作成・実行
try {
    $jobs = foreach ($file in $files) {
        Start-ThreadJob -ScriptBlock $scriptBlock -ThrottleLimit $maxParallelJobs -ArgumentList $file
    }
    Write-Host "Jobs created."
}
catch {
    Write-Error "Error creating jobs: $_"
}

# ジョブ出力を表示
$jobResults = Receive-Job -Job $jobs -Wait
foreach ($result in $jobResults) {
    Write-Output $result
}

# ジョブ完了後クリーンアップ
Remove-Job -Job $jobs
