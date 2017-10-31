rm 6572_kk_list.txt
touch 6572_kk_list.txt
echo "project	MANUFACTURER	BRAND	MODEL" >> 6572_kk_list.txt
for project in $(ls mt6572_kk_alps/mediatek/config/);
do
{
	if [ -f mt6572_kk_alps/mediatek/config/$project/product_appinfo.mk ]
		then
		#MANUFACTURER=$(grep -rn "^PRODUCT_MANUFACTURER" mt6572_kk_alps/mediatek/config/$project/product_appinfo.mk | awk -F"=" '{print $2}')
		BRAND=$(grep -rn "^PRODUCT_BRAND" mt6572_kk_alps/mediatek/config/$project/product_appinfo.mk | awk -F"=" '{print $2}')
		MODEL=$(grep -rn "^PRODUCT_MODEL" mt6572_kk_alps/mediatek/config/$project/product_appinfo.mk | awk -F"=" '{print $2}')
		#echo "$project	$MANUFACTURER	$BRAND	$MODEL" >> 6572_kk_list.txt
		echo "$project	$BRAND	$MODEL" >> 6572_kk_list.txt
	fi
};
done;
