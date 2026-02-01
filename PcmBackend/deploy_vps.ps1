$ErrorActionPreference = "Stop"

$VPS_IP = "103.170.123.164"
$VPS_USER = "root"
$VPS_PASS = "K8vGMSljZng2dXq9" # Note: SCP/SSH might prompt if keys aren't set up.
$LOCAL_ZIP = "d:\MOBILE_FLUTTER_1771020761_NGUYEN-VONG\PcmBackend\backend_deploy.zip"
$REMOTE_DIR = "/www/wwwroot/api"
$APP_NAME = "PcmBackend"

Write-Host "=== Bắt đầu Deploy lên VPS $VPS_IP ===" -ForegroundColor Cyan

# 1. Upload
Write-Host "1. Đang upload file backend_deploy.zip..." -ForegroundColor Yellow
Write-Host "   (Nếu được hỏi mật khẩu, hãy nhập: $VPS_PASS)" -ForegroundColor Gray
scp $LOCAL_ZIP ${VPS_USER}@${VPS_IP}:/tmp/backend_deploy.zip

# 2. Extract & Setup on VPS
Write-Host "2. Đang giải nén và cấu hình trên VPS..." -ForegroundColor Yellow
$commands = @(
    "echo '--- Connected to VPS ---'",
    "mkdir -p $REMOTE_DIR",
    "rm -rf $REMOTE_DIR/*",
    "unzip -o /tmp/backend_deploy.zip -d $REMOTE_DIR",
    "rm /tmp/backend_deploy.zip",
    "chmod +x $REMOTE_DIR/$APP_NAME",
    "pkill -f $APP_NAME || true", # Kill old process if running
    "nohup $REMOTE_DIR/$APP_NAME --urls 'http://0.0.0.0:5266' > $REMOTE_DIR/app.log 2>&1 &", # Start new process
    "echo '--- Deployment Complete ---'",
    "ps aux | grep $APP_NAME"
)

# Join commands with semicolons for one-line execution
$ssh_cmd = $commands -join "; "
ssh ${VPS_USER}@${VPS_IP} "$ssh_cmd"

Write-Host "=== Deploy Hoàn Tất! ===" -ForegroundColor Green
Write-Host "Backend đang chạy tại: http://${VPS_IP}:5266/swagger" -ForegroundColor Cyan
