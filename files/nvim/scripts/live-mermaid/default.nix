{
  writeShellApplication,
  nodePackages,
}:
writeShellApplication {
  name = "live-mermaid";
  runtimeInputs = [
    # nodePackages.live-server # 上游不再维护
  ];
  text = ''
    if (( $# != 1 )); then
      echo "Usage: live-mermaid <file.mmd>"
      exit 1
    fi
    live-server --mount=/:${./index.html} --mount=/index.mmd:"$1" --watch="$1"
  '';
}
