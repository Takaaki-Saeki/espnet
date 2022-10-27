while IFS=',' read -ra array; do
    langs_all+=("${array[0]}")
done < csv/mean_mos_langs.csv
echo ${langs_all}