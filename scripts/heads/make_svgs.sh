pixel2svg() {
    /c/Python27/python ~/Scripts/python/pixel2svg-0.3.0/pixel2svg.py $1
}

# for f in heads/*;
# do
#     echo $f
#     pixel2svg $f
# done
# mv heads/*.svg svgheads

for f in bodies/*;
do
    echo $f
    pixel2svg $f
done
mv bodies/*.svg svgbodies
