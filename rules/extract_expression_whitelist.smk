"""Extract expression fof single species"""

#Which rules will be run on the host computer and not sent to nodes
localrules: plot_rna_metrics, merge_umi, merge_counts

rule extract_umi_expression:
    input:
        data='data/{sample}_final.bam',
        barcode_whitelist='barcodes.csv'
    output:
        dense='summary/{sample}_umi_expression_matrix.tsv',
        sparse='summary/{sample}_umi_expression_matrix.mtx'
    params:
        summary='summary/{sample}_dge.summary.txt',
        count_per_umi=config['EXTRACTION']['minimum-counts-per-UMI'],
        num_cells=lambda wildcards: int(samples.loc[wildcards.sample,'expected_cells']),
        cellBarcodeEditDistance=config['EXTRACTION']['UMI-edit-distance'],
        temp_directory=config['LOCAL']['temp-directory'],
        memory=config['LOCAL']['memory']
    conda: '../envs/dropseq_tools.yaml'
    shell:
        """export _JAVA_OPTIONS=-Djava.io.tmpdir={params.temp_directory} && DigitalExpression -m {params.memory}\
        I={input}\
        O={output.dense}\
        EDIT_DISTANCE={params.cellBarcodeEditDistance}\
        SUMMARY={params.summary}\
        OUTPUT_LONG_FORMAT={output.sparse}\
        STRAND_STRATEGY=SENSE\
        OUTPUT_READS_INSTEAD=false\
        MIN_BC_READ_THRESHOLD={params.count_per_umi}\
        CELL_BC_FILE={input.barcode_whitelist}"""

rule extract_counts_expression:
    input:
        data='data/{sample}_final.bam',
        barcode_whitelist='barcodes.csv'
    output:
        dense='summary/{sample}_counts_expression_matrix.tsv',
        sparse='summary/{sample}_counts_expression_matrix.mtx'
    params:
        summary='summary/{sample}_dge.summary.txt',
        count_per_umi=config['EXTRACTION']['minimum-counts-per-UMI'],
        num_cells=lambda wildcards: int(samples.loc[wildcards.sample,'expected_cells']),
        cellBarcodeEditDistance=config['EXTRACTION']['UMI-edit-distance'],
        temp_directory=config['LOCAL']['temp-directory'],
        memory=config['LOCAL']['memory']
    conda: '../envs/dropseq_tools.yaml'
    shell:
        """export _JAVA_OPTIONS=-Djava.io.tmpdir={params.temp_directory} && DigitalExpression -m {params.memory}\
        I={input}\
        O={output.dense}\
        EDIT_DISTANCE={params.cellBarcodeEditDistance}\
        SUMMARY={params.summary}\
        OUTPUT_LONG_FORMAT={output.sparse}\
        STRAND_STRATEGY=SENSE\
        OUTPUT_READS_INSTEAD=true\
        MIN_BC_READ_THRESHOLD={params.count_per_umi}\
        CELL_BC_FILE={input.barcode_whitelist}"""


rule SingleCellRnaSeqMetricsCollector:
    input:
        data='data/{sample}_final.bam',
        barcode_whitelist='barcodes.csv',
        refFlat="{}.refFlat".format(annotation_prefix),
        rRNA_intervals="{}.rRNA.intervals".format(reference_prefix)
    params:     
        temp_directory=config['LOCAL']['temp-directory'],
        memory=config['LOCAL']['memory']
    output:
        'logs/{sample}_rna_metrics.txt'
    conda: '../envs/dropseq_tools.yaml'
    shell:
        """export _JAVA_OPTIONS=-Djava.io.tmpdir={params.temp_directory} && SingleCellRnaSeqMetricsCollector -m {params.memory}\
        INPUT={input.data}\
        OUTPUT={output}\
        ANNOTATIONS_FILE={input.refFlat}\
        CELL_BC_FILE={input.barcode_whitelist}\
        RIBOSOMAL_INTERVALS={input.rRNA_intervals}
        """

rule plot_rna_metrics:
    input:
        rna_metrics='logs/{sample}_rna_metrics.txt',
        barcodes='barcodes.csv'
    conda: '../envs/plots.yaml'
    output:
        pdf='plots/{sample}_rna_metrics.pdf',
    script:
        '../scripts/plot_rna_metrics.R'

rule merge_umi:
    input:
        expand('summary/{sample}_umi_expression_matrix.tsv', sample=samples.index)
    params:
        sample_names=lambda wildcards: samples.index
    conda: '../envs/merge.yaml'
    output:
        'summary/umi_expression_matrix.tsv'
    script:
        "../scripts/merge_counts_single.R"

rule merge_counts:
    input:
        expand('summary/{sample}_counts_expression_matrix.tsv', sample=samples.index)
    params:
        sample_names=lambda wildcards: samples.index
    conda: '../envs/merge.yaml'
    output:
        'summary/counts_expression_matrix.tsv'
    script:
        "../scripts/merge_counts_single.R"
