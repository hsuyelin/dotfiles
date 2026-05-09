_xcode_dev="/Applications/Xcode.app/Contents/Developer"
if [[ -d "$_xcode_dev" ]]; then
    export DEVELOPER_DIR="$_xcode_dev"
    path=("$DEVELOPER_DIR/usr/bin" $path)
fi
unset _xcode_dev
