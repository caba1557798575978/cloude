from pyspark import SparkContext

def main():
    sc = SparkContext(appName="WordCount")
    
    # 读取 README 文件
    lines = sc.textFile("/opt/spark/README.md")
    
    # 分词并计数
    counts = lines.flatMap(lambda x: x.split()) \
                  .map(lambda x: (x, 1)) \
                  .reduceByKey(lambda a, b: a + b)
    
    # 输出结果
    output = counts.collect()
    for word, count in output:
        print(f"{word}: {count}")
    
    sc.stop()

if __name__ == "__main__":
    main()
