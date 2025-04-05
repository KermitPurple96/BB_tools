jqurls() {
  jq -r '.[].url' "$1"
}

jqsubs() {
  jq -r '.[].subdomain' "$1" | sort -u
}

jqips() {
  jq -r '.[].ip' "$1" | tr ',' '\n' | sort -u
}

jqcnames() {
  jq -r '.[].cname' "$1" | tr ',' '\n' | sort -u
}

jqasn() {
  jq -r '.[].asn' "$1" | tr ',' '\n' | sort -u
}

jqcidr() {
  jq -r '.[].cidr' "$1" | tr ',' '\n' | sort -u
}

jqorg() {
  jq -r '.[].org' "$1" | tr ',' '\n' | sort -u
}

jqstatus() {
  jq -r '.[] | "\(.url) => [\(.status)] \(.reason)"' "$1"
}

jqbanner() {
  jq -r '.[] | select(.banner != "") | "\(.url) => \(.banner)"' "$1"
}
