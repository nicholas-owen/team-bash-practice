##master script to prepare a project and run processing of samples
#!/bin/bash
##
set +e
set +x

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PINK='\033[0;35m'
PURPLE='\033[0;34m'
NC='\033[0m' # No Color

#                                                                                                                                             https://stackoverflow.com/questions/5014632/how-can-i-parse-a-yaml-file-from-a-linux-shell-script

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}


eval $(parse_yaml project.config.yaml)
eval $(parse_yaml server.config.yaml)

#1.

run_mode="$1"



if [ -z $run_mode ] ; then
    echo -e ""
    echo -e "No run mode specified. Please refer to the following information to help you choose your run mode."
    echo -e ""
    echo -e "${RED}RUN MODES:${NC}"
    echo -e ""
    echo -e "Project Initiation:"
    echo -e "~~~~~~~~~~~~~~~~~~~"
    echo -e "     ${YELLOW}--prepare_project${NC}                             Set up the project directory script and payload scripts"
    echo -e "     ${YELLOW}--prepare_support${NC}                             Prepare support table file for all samples"
    echo -e "     ${YELLOW}--prepare_support_trim${NC}                        Prepare support table file for processed FASTQ files (TrimGalore)"
    echo -e ""
    echo -e "Quality Control/Processing:"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo -e "     ${YELLOW}--fastqc${NC}                                      Run FASTQC on samples"
    echo -e "     ${YELLOW}--trim_adapt${NC}                                  Run Trimgalore on samples to remove adapters and process low score calls"
    echo -e "     ${YELLOW}--trim_adapt_fa${NC}                               Run FASTP on samples to remove adapters and process low score calls, specifying adapter.fa sequences"
    echo -e "     ${YELLOW}--multiqc${NC}                                     MultiQC report generation"
    echo -e "     ${YELLOW}--multiqc fastqc${NC}                              Generate MultiQC report for FASTQC of raw FASTQ files"
    echo -e "     ${YELLOW}--multiqc fastqc-trimmed${NC}                      Generate MultiQC report for FASTQC of trimmed FASTQ files"
    echo -e "     ${YELLOW}--multiqc trim_adapt${NC}                          Generate MultiQC report for the TrimGalore statistics"
    echo -e ""
    echo -e "Read Alignment and Metrics:"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo -e "     ${YELLOW}--index <hisat2>${NC}                              Generate index files for the species appropriate to the project"
    echo -e "     ${YELLOW}--align <kallisto/hisat2/star/salmon>${NC}         Generate RNA-seq pseudoalignments and expression counts with Kallisto/Salmon"
    echo -e "                                                           or align FASTQ reads with HISAT2/STAR"
    echo -e "     ${YELLOW}--bam_process${NC}                                 Process unsorted BAM alignment files into sorted and indexed."
    echo -e "     ${YELLOW}--bam_validate <hisat2/star>${NC}                  Validate BAM alignment files have been correctly generated."
    echo -e "     ${YELLOW}--qorts <metrics/noveljunc>${NC}                   Generate QORTS metrics for STAR aligned BAM files (metrics) or for noveljuncs."
    echo -e "     ${YELLOW}--metrics <RNA-SeQC/picardmetrics/qualimap//TODO>${NC} #6   Generate metric reports for the BAM files using various tools."
    echo -e "     ${YELLOW}--multiqc bam <hisat2/star>${NC}                   Generate MultiQC report for the BAM alignment statistics"
    echo -e "     ${YELLOW}--multiqc qualimap <hisat2/star>${NC}              Generate MultiQC report for the Qualimap reports of the BAM alignments"
    echo -e ""
    echo -e "Feature Analysis:"
    echo -e "~~~~~~~~~~~~~~~"
    echo -e "     ${YELLOW}--counts_htseq ${PURPLE}REDACTED${NC}                       Generate count files using HTSeq-counts keeping read duplicates."
    echo -e "     ${YELLOW}--counts_fc <hisat2/star>${NC}                     Generate count files using featurecounts keeping read duplicates."
    echo -e "     ${YELLOW}--stringtie <GTF/denovo/merge/abund>${NC}          Create transcript files using Stringtie from HISAT2 alignments."
    echo -e "     ${YELLOW}--majiq <build/quant/viola>${NC}                   Local Splice Variation (LSV) analysis using MAJIQ."
    echo -e ""
    echo -e ""
    echo -e "Variant Calling:"
    echo -e "~~~~~~~~~~~~~~~"
    echo -e "     ${PURPLE}--call_variants <splitN/recal/callvar>${NC}        Variant calling pipeline for RNA-seq data"
    echo -e "           						splitN - split N CIGARs in STAR aligned BAM"
    echo -e "     							recal - recalibrate base scoring using known sites"
    echo -e "     							callvar - call variants using MuTech2"
    echo -e "                               convert_gvcf2vcf - convert MuTech2 GVCF to VCF"
    echo -e ""
    echo -e "Utilities:"
    echo -e "~~~~~~~~~~"
    echo -e "     ${GREEN}--get_ref <species> <ver>${NC}                    Download reference genome and annotation files"
    echo -e ""
    echo -e "     ${BLUE}--help${NC}                                        Help documentation."
    echo -e "     ${PINK}--version${NC}                                     Script version."
    echo -e "     ${RED}--sanity${NC}                                      Sanity check that project support files have been created correctly."
    echo -e ""
    
    exit 1
fi

if [ $run_mode = "--help" ] ; then
    
    echo "HELP COMING SOON"
    exit 1
fi

if [ $run_mode = "--version" ] ; then
    echo ""
    echo  -e "version: ${PINK}0.81a-2023-03-17 Private Build${NC}"
    echo ""
    exit 1
fi

## CHECK CONFIGS
if [[ ! -f ./project.config ]]; then
 usage
 echo "Error: configuration file (project.config) is missing!"
 exit 1
fi

if [[ ! -f ./server.config ]]; then
 usage
 echo "Error: configuration file (server.config) is missing!"
 exit 1
fi


###PREPARE PROJECT SECTION

if [ $run_mode = "--prepare_project" ] ; then
    
    #get $PWD in for project_location to read project.config file
    
    projectconfigloc=$PWD
    
    echo ""
    echo ""
    
    #if [[ $# -eq 0 ]] ; then
    if [ -z $projectconfigloc ] ; then
        echo ''
        echo -e "${RED}No arguments supplied.....${NC}"
        echo ''
        echo -e "${YELLOW}Usage:${NC} bash RNAseq.sh --prepare_project <project_location>"
        echo -e "where the ${YELLOW}<project_location>${NC}  is the complete path of the project parent directory."
        echo ''
        echo ''
        exit 1
    fi
    
    #check project.config exists
    if [ -e ${projectconfigloc}/project.config ]
    then
        echo ""
        echo "Project Configuration file found."
    else
        echo ""
        echo -e "${RED}No project.config file present in that location. Please check your files.${NC}"
        exit 1
    fi
    
    #check server.config exists
    if [ -e ${projectconfigloc}/server.config ]
    then
        echo ""
        echo "Server Configuration file found."
    else
        echo ""
        echo -e "${RED}No server.config file present in that location. Please check your files.${NC}"
        exit 1
    fi
    
    ###IMPORT MAIN PROJECT CONFIGURATION FILE
    config_file=${projectconfigloc}/project.config
    server_file=${projectconfigloc}/server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    
    folder="cluster cluster/scripts cluster/output fastq fastq/trimmed_q6 bam bam/kallisto bam/star bam/hisat2 reports reports/fastqc reports/multiqc  reports/qualimap R kallisto htseq stringtie counts/hisat2 counts/star"
    cd ${projectconfigloc}
    
    echo -e "Reading Project Configuration file: ${project_config_loc}/project.config"
    echo -e "Reading Server Configuration file: ${project_config_loc}/server.config"
    echo -e ""
    echo -e "Creating directory structure:"
    for i in $folder
    do echo -e ${RED}$i
        mkdir -p ${projectconfigloc}/$i
    done
    echo -e ""
    echo -e "${YELLOW}Unpacking template payload...."
    echo -e "${NC}"
    
    ###sorting payload files and editing the PROJECTLOCATION to the {projectconfigloc}
    echo ""
    echo -e "${YELLOW}Copying:${NC} qsub_multiple.sh script"
    cat ./project_payload/project_qsub_multiple.sh | sed -e "s@PROJECTLOCATION@$projectconfigloc@g"   > ./cluster/scripts/qsub_multiple.sh
    echo -e "${YELLOW}Copying:${NC} prepare_trimmed_q6_support.sh script"
    cat ./project_payload/project_prepare_trimmed_q6_support.sh | sed -e "s@PROJECTLOCATION@$projectconfigloc@g"   > ./cluster/scripts/prepare_trimmed_q6_support.sh
    echo -e "${YELLOW}Copying:${NC} prepare_project.sh script"
    cat ./project_payload/prepare_project.sh  | sed -e "s@PROJECTLOCATION@$projectconfigloc@g"   > ./cluster/scripts/prepare_project.sh
    echo -e "${YELLOW}Copying:${NC} project_prepare_fastqc_scripts.sh script"
    cat ./project_payload/project_prepare_fastqc_scripts.sh  | sed -e "s@PROJECTLOCATION@$projectconfigloc@g"   > ./cluster/scripts/prepare_fastqc_scripts.sh
    echo -e "${YELLOW}Copying:${NC} project_prepare_trimming_script.sh script"
    cat ./project_payload/project_prepare_trimming_script.sh  | sed -e "s@PROJECTLOCATION@$projectconfigloc@g"   > ./cluster/scripts/prepare_trimming_script.sh
    
    echo -e "${YELLOW}Copying:${NC} project_prepare_bam_process_scripts.sh script"
    cat ./project_payload/project_prepare_bam_process_scripts.sh  | sed -e "s@PROJECTLOCATION@$projectconfigloc@g"   > ./cluster/scripts/project_prepare_bam_process_scripts.sh
    
    
    echo ""
    echo -e "${YELLOW}Please ensure all FASTQ files are copied to $projectconfigloc/fastq .${NC}"
fi
###end of --prepare_project section



###-- prepare_support PREPARE SUPPORT FILES


if [ $run_mode = "--prepare_support" ] ; then
    fastq_ext="$2"
    echo -e ""
    echo -e ""
    
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    
    if [ -z $fastq_ext ] ; then
        echo ''
        echo -e "${RED}No arguments supplied.....${NC}"
        echo ''
        echo -e "${YELLOW}Usage:${NC} bash prepare_project.sh '${RED}<file_ext>${NC}'"
        echo -e "where the ${RED}<file_ext>${NC} is the file extension of the FASTQ files for the project."
        echo 'Please note the FASTQ files should contain R1 and R2 in the names. Please ensure you include the leading . ie .fq.gz'
        echo ''
        echo -e "${YELLOW}Description:${NC}"
        echo 'To produce support files for a new project whilst creating necessary folder structures for handling the data.'
        echo 'By reading the project.conf file that is set in the variable config_file, this script will create a listing '
        echo 'of all the samples from the FASTQ files stored. Two output files will be created in the main project location:'
        echo ''
        echo -e "Project Location: ${YELLOW}${project_data_loc}${NC}"
        echo -e "Project Support Files: ${YELLOW}${project_code}_support.tab${NC}, ${YELLOW}${project_code}_samples.tab${NC}"
        echo ''
        exit 1
    fi
    
    echo "Searching for ....${fastq_ext} files."
    
    echo "sample f1 f2" > ${project_data_loc}/${project_code}_support.tab
    echo "" > ${project_data_loc}/${project_code}_samples.tab
    echo "" > ${project_data_loc}/${project_code}_fastq_raw.tab
    
    if [ ${sample_paired} = TRUE ] ; then
        
        for R1 in `find ${fastq_loc} -name \*1${fastq_ext}`; do
            R2=`echo $R1 | sed -e 's/1${fastq_ext}/2${fastq_ext}/g'`  ##needs regular changing
            
            R1=`basename $R1`
            R2=`basename $R2`
            
            code=`basename $R1 | sed -e 's/1${fastq_ext}//g'`
            echo "$code $R1 $R2" >> ${project_data_loc}/${project_code}_support.tab
            echo "$code" >> ${project_data_loc}/${project_code}_samples.tab
            echo "$R1" >> ${project_data_loc}/${project_code}_fastq_raw.tab
            echo "$R2" >> ${project_data_loc}/${project_code}_fastq_raw.tab
        done
    fi
    
    if [ ${sample_paired} = FALSE ] ; then
        for R1 in `find ${fastq_loc} -name \*.fq.gz`; do
            R1=`basename $R1`
            code=`basename $R1 | sed -e 's/.fq.gz//g'`
            echo "$code $R1" >> ${project_data_loc}/${project_code}_support.tab
            echo "$code" >> ${project_data_loc}/${project_code}_samples.tab
            echo "$R1" >> ${project_data_loc}/${project_code}_fastq_raw.tab
        done
    fi
    
    #echo -e "Executing script to prepare support files:"
    #bash ./cluster/scripts/prepare_project.sh ${fastq_ext}
    
    
    
    echo -e "Support files: ${project_data_loc}/${project_code}_samples.tab,  ${project_code}_support.tab and ${project_code}_fastq_raw.tab created."
    
    
    #creates directories for STAR alignment files
    while read line; do mkdir -p "${project_data_loc}/bam/star/${line%/*}"; done < ${project_data_loc}/${project_code}_samples.tab
    
    #created directories for KALLISTO count files
    while read line; do mkdir -p "${project_data_loc}/kallisto/${line%/*}"; done < ${project_data_loc}/${project_code}_samples.tab
    
    #created directories for HISAT2 BAM files
    while read line; do mkdir -p "${project_data_loc}/bam/hisat2/${line%/*}"; done < ${project_data_loc}/${project_code}_samples.tab
    
    #created directories for STRINGTIE  COUNT files
    while read line; do mkdir -p "${project_data_loc}/stringtie/${line%/*}"; done < ${project_data_loc}/${project_code}_samples.tab
    
    #created directories for STRINGTIE  ABUNDANCE files
    while read line; do mkdir -p "${project_data_loc}/ballgown/${line%/*}"; done < ${project_data_loc}/${project_code}_samples.tab
    
    #created directories for QORTS files
    while read line; do mkdir -p "${project_data_loc}/qorts/${line%/*}"; done < ${project_data_loc}/${project_code}_samples.tab
    
    #creates directories for SALMON files
    while read line; do mkdir -p "${project_data_loc}/counts/salmon/${line%/*}"; done < ${project_data_loc}/${project_code}_samples.tab
    
    echo -e "Created sample specific directories under /kallisto/, /stringtie/ , /ballgown/ and /bam/star/+/hisat2/, /qorts, /counts "
    
fi





###FASTQC analysis of FASTQ files

if [ $run_mode = "--fastqc" ] ; then
    
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    
    fastqc_files="$2"
    report_output="$3"
    
    if [ -z $fastqc_files ] ; then
        echo -e ""
        echo -e "${RED}No FASTQ files specified.${NC}"
        echo -e ""
        echo -e "     Please specify a plain text file listing all FASTQ samples to be assayed."
        echo -e "     Format: one fastq (or gz'd archive) per line"
        echo -e "     Usage: ${YELLOW}--fastqc <filename.ext> <report_dir_output>${NC}"
        echo -e ""
        exit 1
    fi
    
    if [ -z $report_output ] ; then
        echo -e ""
        echo -e "${RED}No report output directory specified.${NC}"
        echo -e ""
        echo -e "     Please specify a directory that will be used under ${reports_fastqc} for this analysis."
        echo -e "     Usage: ${YELLOW}--fastqc <report_dir_output>${NC}"
        echo -e ""
        
        exit 1
    fi
    
    echo -e "Creating report output directory: ${RED}${reports_fastqc}/${report_output}${NC}"
    
    mkdir "${reports_fastqc}/${report_output}"
    
    #bash ./cluster/scripts/prepare_fastqc_scripts.sh ${fastqc_files} ${report_output}
    
    mkdir ${reports_fastqc}/${report_output}
    while IFS='' read -r line
    do
        file_name="$line"
        echo "Filename read from file - $file_name"
        script_file=`echo $file_name | awk -F '/' '{print $NF}'`
        
        echo "Creating script: $script_file."
        echo "#$ -l h_vmem=3.9G" > ${cluster_scripts_loc}/fastqc_$script_file.sh
        echo "#$ -l tmem=3.9G" >> ${cluster_scripts_loc}/fastqc_$script_file.sh
        echo "#$ -l h_rt=2:0:0" >> ${cluster_scripts_loc}/fastqc_$script_file.sh
        echo "#$ -pe smp 1" >> ${cluster_scripts_loc}/fastqc_$script_file.sh
        echo "#$ -j y" >> ${cluster_scripts_loc}/fastqc_$script_file.sh
        echo "#$ -R y" >> ${cluster_scripts_loc}/fastqc_$script_file.sh
        echo "#$ -o ${cluster_output_loc}" >> ${cluster_scripts_loc}/fastqc_$script_file.sh
        echo "#$ -e ${cluster_output_loc}" >> ${cluster_scripts_loc}/fastqc_$script_file.sh
        echo "#$ -S /bin/bash" >> ${cluster_scripts_loc}/fastqc_$script_file.sh
        echo "export JAVA_HOME=${javaFolder}" >> ${cluster_scripts_loc}/fastqc_$script_file.sh
        echo "export PATH=$PATH:${javaFolder}:" >> ${cluster_scripts_loc}/fastqc_$script_file.sh
        echo "${fastqcFolder}/fastqc ${fastq_loc}/$file_name -o ${reports_fastqc}/$report_output" >> ${cluster_scripts_loc}/fastqc_$script_file.sh
        echo -e "Submitting job to cluster: ${YELLOW}fastqc_${script_file}.sh${NC}"
        qsub ${cluster_scripts_loc}/fastqc_$script_file.sh
    done < "$fastqc_files"
    
    
fi




###TRIMGALORE adapter and trimming processing of raw FASTQ files

if [ $run_mode = "--trim_adapt" ] ; then
    
    echo "Executing prepare_trimming_script.sh"
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    
    #bash ./cluster/scripts/prepare_trimming_script.sh
    input_name="${project_data_loc}/${project_code}_support.tab"
    output_dir="${fastq_trimmed_loc}"
    
    echo ""
    echo "Filename read from file - $input_name"
    echo ""
    
    if [ ! -f $input_name ] ; then
        echo -e "${RED}Input file does not exist.${NC}"
        echo -e "Please ensure your FASTQ support file has been created:${sample_fastq_raw}"
        exit 1
        
    fi
    
    while IFS=' ' read -r sample_name read1_name read2_name
    do
        sample_name="$sample_name"
        read1_name="$read1_name"
        read2_name="$read2_name"
        d=$(date +%Y-%m-%d)
        
        if [ $sample_name != "sample" ] ; then
            
            echo -e "${YELLOW}Input sample:${NC} $sample_name    ${YELLOW}Reads:${NC} $read1_name $read2_name ${YELLOW}Script:${NC} trimgalore_$d_$sample_name.sh"
            echo "#$ -l h_vmem=1.9G" > ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "#$ -l tmem=1.9G" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "#$ -l h_rt=2:0:0" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "#$ -l tscratch=100G" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "#$ -pe smp 4" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "#$ -j y" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "#$ -R y" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "#$ -o ${cluster_output_loc}" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "#$ -e ${cluster_output_loc}" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "#$ -S /bin/bash" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "#$ -N trimgalore_${sample_name}" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "export PATH=${pythonFolder}:$PATH" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "#" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            #echo "scratchLoc=/scratch0/$USER/trim" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            echo "mkdir -p ${scratchLoc}/\$JOB_ID" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
            
            if [ $sample_paired = TRUE ] ; then
                
                echo "${trimgaloreFolder}/trim_galore --gzip --cores 4 -o ${scratchLoc}/\$JOB_ID --quality 6 --path_to_cutadapt ${cutadaptFolder}/cutadapt --paired ${fastq_loc}/${read1_name} ${fastq_loc}/${read2_name}" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
                echo "cp -p ${scratchLoc}/\$JOB_ID/* ${fastq_trimmed_loc}/" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
                echo "function finish {
				rm -rf /scratch0/smgxnow/\$JOB_ID
				}
                trap finish EXIT ERR INT TERM" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
                
            fi
            
            if  [ $sample_paired = FALSE ] ; then
                
                echo "${trimgaloreFolder}/trim_galore --gzip -o ${fastq_trimmed_loc} --quality 6 --path_to_cutadapt ${cutadaptFolder}/cutadapt  ${fastq_loc}/${read1_name}" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
                echo "${trimgaloreFolder}/trim_galore --gzip -o ${fastq_trimmed_loc} --quality 6 --path_to_cutadapt ${cutadaptFolder}/cutadapt  ${fastq_loc}/${read2_name}" >> ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
                
            fi
        fi
        
        echo -e "Script creation complete: ${RED}trimgalore_${d}_$sample_name.sh${NC}"
        echo -e ""
        echo -e "Submitting job to cluster: ${YELLOW}trimgalore_${d}_$sample_name.sh${NC}"
        qsub ${cluster_scripts_loc}/trimgalore_$d_$sample_name.sh
        
    done < "$input_name"
    
    echo ""
    echo -e "Processed FASTQ files will be located at: ${YELLOW}${fastq_trimmed_loc}${NC}"
    
    
    
fi


### FASTP adapter and trimming processing of raw FASTQ files, specifying adapter.fa sequence file for specific adapter removal

if [ $run_mode = "--trim_adapt_fa" ] ; then
    
    echo "Trimming with FASTP and specified adapter sequences as adapters.fa "
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    
    input_name="${project_data_loc}/${project_code}_support.tab"
    output_dir="${fastq_trimmed_loc}"
    adapter_fa="${project_data_loc}/adapters.fa"
    
    echo ""
    echo "Filename read from file - $input_name"
    echo ""
    
    if [ ! -f $input_name ] ; then
        echo -e "${RED}Input file does not exist.${NC}"
        echo -e "Please ensure your FASTQ support file has been created:${sample_fastq_raw}"
        exit 1
        
    fi
    
    echo "Using external adapter sequence file: ${adapter_fa}"
    
    if [ ! -f $adapter_fa ] ; then
        echo -e "${RED}Adapter FASTA file does not exist.${NC}"
        echo -e "Please ensure your FASTA adapter file has been present:${adapter_fa}"
        exit 1
        
    fi
    
    while IFS=' ' read -r sample_name read1_name read2_name
    do
        sample_name="$sample_name"
        read1_name="$read1_name"
        read2_name="$read2_name"
        d=$(date +%Y-%m-%d)
        
        if [ $sample_name != "sample" ] ; then
            
            echo -e "${YELLOW}Input sample:${NC} $sample_name    ${YELLOW}Reads:${NC} $read1_name $read2_name ${YELLOW}Script:${NC} fastp_$d_$sample_name.sh"
            echo "#$ -l h_vmem=1.9G" > ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "#$ -l tmem=1.9G" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "#$ -l h_rt=2:0:0" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "#$ -l tscratch=100G" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "#$ -pe smp 4" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "#$ -j y" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "#$ -R y" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "#$ -o ${cluster_output_loc}" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "#$ -e ${cluster_output_loc}" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "#$ -S /bin/bash" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "#$ -N fastp_${sample_name}" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "export PATH=${pythonFolder}:$PATH" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "#" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            #echo "scratchLoc=/scratch0/$USER/trim" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            echo "mkdir -p ${scratchLoc}/\$JOB_ID" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
            
            if [ $sample_paired = TRUE ] ; then
                
                echo "${fastpFolder}/fastp  -i ${fastq_loc}/${read1_name} -I ${fastq_loc}/${read2_name} -o ${scratchLoc}/\$JOB_ID/${read1_name} -O ${scratchLoc}/\$JOB_ID/${read2_name} -q 6 -p --adapter_fasta=${adapter_fa} -h ${fastq_trimmed_loc}/${read1_name}_${read2_name}_fastp_report.html" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
                echo "cp -p ${scratchLoc}/\$JOB_ID/* ${fastq_trimmed_loc}/" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
                echo "function finish {
				rm -rf /scratch0/smgxnow/\$JOB_ID
				}
                trap finish EXIT ERR INT TERM" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
                
            fi
            
            if  [ $sample_paired = FALSE ] ; then
                
                echo "${fastpFolder}/fastp  -i ${fastq_loc}/${read1_name} -q 6 -o ${scratchLoc}/\$JOB_ID/${read1_name} -p --adapter_fasta=${adapter_fa} -h ${fastq_trimmed_loc}/${read1_name}_fastp_report.html" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
                echo "${fastpFolder}/fastp  -i ${fastq_loc}/${read2_name} -q 6 -o ${scratchLoc}/\$JOB_ID/${read2_name} -p --adapter_fasta=${adapter_fa} -h ${fastq_trimmed_loc}/${read2_name}_fastp_report.html" >> ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
                
            fi
        fi
        
        echo -e "Script creation complete: ${RED}fastp_${d}_$sample_name.sh${NC}"
        echo -e ""
        echo -e "Submitting job to cluster: ${YELLOW}fastp_${d}_$sample_name.sh${NC}"
        qsub ${cluster_scripts_loc}/fastp_$d_$sample_name.sh
        
    done < "$input_name"
    
    echo ""
    echo -e "Processed FASTQ files will be located at: ${YELLOW}${fastq_trimmed_loc}${NC}"
    
    
    
fi






###PREPARE support file for trimmed q6 FASTQ files

if [ $run_mode = "--prepare_support_trim" ] ; then
    echo ""
    echo "Preparing support matrix files for trimmed data.."
    echo ""
    
    fastq_ext="$2"
    echo -e ""
    echo -e ""
    
    if [ -z $fastq_ext ] ; then
        echo ''
        echo -e "${RED}No arguments supplied.....${NC}"
        echo ''
        echo -e "${YELLOW}Usage:${NC} bash ./RNAseq.sh --prepare_support_trim '${RED}<file_ext>${NC}'"
        echo -e "where the ${RED}<file_ext>${NC} is the file extension of the trimmed FASTQ files for the project."
        echo 'Please note the FASTQ files should contain R1 and R2 in the names or variants of.'
        echo ' for example using _1_001_val_1.fq.gz'
        echo ''
        exit 1
    fi
    
    
    
    #bash ./cluster/scripts/prepare_trimmed_q6_support.sh
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    
    echo "sample f1 f2" >  ${project_data_loc}/${project_code}_support_trimmed.tab
    echo "" > ${project_data_loc}/${project_code}_fastq_trimmed.tab
    
    
    for R1 in `find ${fastq_trimmed_loc} -name \*1${fastq_ext}`; do
        R2=`echo $R1 |  sed -e 's/11${fastq_ext}/2${fastq_ext}/g'`
        
        R1=`basename $R1`
        R2=`basename $R2`
        
        code=`basename $R1 |  sed -e 's/1${fastq_ext}//g'`
        echo "$code $R1 $R2" >>  ${project_data_loc}/${project_code}_support_trimmed.tab
        #echo "$code $R1 $R2" >>  ${project_data_loc}/${project_code}_trimmed_q6_fastq_files.tab # ORIGINAL
        echo "/trimmed_q6/$R1" >> ${project_data_loc}/${project_code}_fastq_trimmed.tab
        echo "/trimmed_q6/$R2" >> ${project_data_loc}/${project_code}_fastq_trimmed.tab
        
        
    done
    
    echo -e " Created output support files: ${YELLOW}${project_code}_support_trimmed.tab$  ${project_code}_fastq_trimmed.tab${NC} ..."
    
    
fi



###MULTIQC analysis report generation - FASTQC trimmed

if [ $run_mode = "--multiqc" ] ; then
    
    multiqc_mode="$2"
    
    
    if [ -z $multiqc_mode ] ; then
        echo -e ""
        echo -e "${RED}No MultiQC mode specified.${NC}"
        echo -e ""
        echo -e "     Please specify the report to generate with MultiQC."
        echo -e "     Usage: ${YELLOW}--multiqc <fastqc/fastqc-trimmed/trim_adapt/qualimap/bam>${NC}"
        echo -e ""
        exit 1
    fi
    
    
    if [ $multiqc_mode = "fastqc" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        raw_dir="$3"
        
        if [ -z $raw_dir ] ; then
            echo -e ""
            echo -e "${RED}No directory containing the FASTQC reports specified.${NC}"
            echo -e ""
            echo -e "     Please specify the report to generate with MultiQC."
            echo -e "     Usage: ${YELLOW}--multiqc fastqc ${YELLOW}<directory>${NC}"
            echo -e ""
            exit 1
        fi
        
        
        
        echo -e ""
        echo -e "Generating MultiQC report of FASTQC analysis of the raw FASTQ files...."
        
        mkdir "${multiqc_reports}/FASTQC_${raw_dir}"
        export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH
        export PATH=${pythonFolder}:$PATH
        ${multiqcFolder}/multiqc -o ${multiqc_reports}/FASTQC_${raw_dir} "${reports_fastqc}/${raw_dir}"
        
    fi
    
    
    
    if [ $multiqc_mode = "fastqc-trimmed" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        raw_dir="$3"
        
        if [ -z $raw_dir ] ; then
            echo -e ""
            echo -e "${RED}No directory containing the FASTQC reports specified.${NC}"
            echo -e ""
            echo -e "     Please specify the report to generate with MultiQC."
            echo -e "     Usage: ${YELLOW}--multiqc fastqc-trimmed ${YELLOW}<directory>${NC}"
            echo -e ""
            exit 1
        fi
        
        
        
        echo -e ""
        echo -e "Generating MultiQC report of FASTQC analysis of the processed (adapters and low scoring bases removed) FASTQ files...."
        
        mkdir -p ${multiqc_reports}/FASTQC_trimmed
        export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH
        export PATH=${pythonFolder}:$PATH
        ${multiqcFolder}/multiqc -o ${multiqc_reports}/FASTQC_trimmed "${reports_fastqc}/${raw_dir}"
        
    fi
    
    if [ $multiqc_mode = "trim_adapt" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        echo -e ""
        echo -e "Generating MultiQC report of TrimGalore adapter removal and low scoring sequence trimming...."
        
        mkdir ${multiqc_reports}/STATS_trimgalore
        export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH
        export PATH=${pythonFolder}:$PATH
        ${multiqcFolder}/multiqc -o ${multiqc_reports}/STATS_trimgalore ${fastq_trimmed_loc}
        
    fi
    
    if [ $multiqc_mode = "qualimap" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        bam_multiqc_quali="$3"
        
        if [ -z $bam_multiqc_quali ] ; then
            echo -e ""
            echo -e "${RED}No BAM alignment reports specified.${NC}"
            echo -e ""
            echo -e "     Please specify the aligned BAM file Qualimap reports to gather."
            echo -e "     Usage: ${YELLOW}--multiqc qualimap ${YELLOW}<hisat2/star>${NC}"
            echo -e ""
            exit 1
        fi
        
        if [ $bam_multiqc_quali = "hisat2" ] ; then
            echo -e ""
            echo -e ""
            echo -e "Generating MultiQC report of aligned BAM files - HISAT2 Qualimap Reports..."
            
            mkdir -p ${multiqc_reports}/qualimap_reports/hisat2
            export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH
            export PATH=${pythonFolder}:$PATH
            ${multiqcFolder}/multiqc -o ${multiqc_reports}/qualimap_reports/hisat2 ${qualimap_reports}/hisat2/ -c ${project_data_loc}/project_payload/multiqc_config_bamstats.yaml -t  default
            echo -e ""
            exit 1
        fi
        
        if [ $bam_multiqc_quali = "star" ] ; then
            echo -e ""
            echo -e ""
            echo -e "Generating MultiQC report of aligned BAM files - STAR Qualimap Reports..."
            
            mkdir -p ${multiqc_reports}/qualimap_reports/star
            export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH
            export PATH=${pythonFolder}:$PATH
            ${multiqcFolder}/multiqc -o ${multiqc_reports}/qualimap_reports/star ${qualimap_reports}/star/ -c ${project_data_loc}/project_payload/multiqc_config_bamstats.yaml -t  default
            echo -e ""
            exit 1
        fi
        
    fi
    
    if [ $multiqc_mode = "bam" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        bam_multiqc_type="$3"
        
        if [ -z $bam_multiqc_type ] ; then
            echo -e ""
            echo -e "${RED}No BAM alignment type specified for MultiQC reporting.${NC}"
            echo -e ""
            echo -e "     Please specify the aligned BAM alignment files to gather stats for."
            echo -e "     Usage: ${YELLOW}--multiqc bam ${YELLOW}<hisat2/star>${NC}"
            echo -e ""
            exit 1
        fi
        
        if [ $bam_multiqc_type = "hisat2" ] ; then
            echo -e ""
            echo -e ""
            echo -e "Generating MultiQC report of aligned BAM files - HISAT2 statistics..."
            
            mkdir -p ${multiqc_reports}/bams-hisat2
            export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH
            export PATH=${pythonFolder}:$PATH
            ${multiqcFolder}/multiqc -c ${project_data_loc}/project_payload/multiqc_config_bamstats.yaml -o ${multiqc_reports}/bams-hisat2 ${bam_hisat_loc} -t  default
            echo -e ""
            exit 1
        fi
        
        if [ $bam_multiqc_type = "star" ] ; then
            echo -e ""
            echo -e ""
            echo -e "Generating MultiQC report of aligned BAM files - STAR statistics..."
            
            mkdir -p ${multiqc_reports}/bams-star
            export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH
            export PATH=${pythonFolder}:$PATH
            ${multiqcFolder}/multiqc  -c ${project_data_loc}/project_payload/multiqc_config_bamstats.yaml -o ${multiqc_reports}/bams-star ${bam_star_loc} -t  default
            echo -e ""
            exit 1
        fi
        
    fi
    
fi




###Kallisto pseudo alignment and counts

if [ $run_mode = "--align" ] ; then
    
    align_mode="$2"
    
    if [ -z $align_mode ] ; then
        echo -e ""
        echo -e "${RED}No alignment mode specified.${NC}"
        echo -e ""
        echo -e "     Please specify an alignment mode for the RNA-seq data."
        echo -e "     Usage: ${YELLOW}--align ${YELLOW}<kallisto/star/star-notrim/bowtie2/hisat2/salmon>${NC}"
        echo -e ""
        exit 1
    fi
    
    if [ $align_mode = "kallisto" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        echo -e ""
        echo -e "Generating Kallisto scripts for count generation and pseudoBAM files...."
        
        cp ./project_payload/project_prepare_kallisto_scripts.R ${cluster_scripts_loc}/prepare_kallisto_scripts.R
        cp ./project_payload/project_kallisto_script_header.txt ${cluster_scripts_loc}/project_kallisto_script_header.txt
        
        ${RFolder}/Rscript ${cluster_scripts_loc}/prepare_kallisto_scripts.R
        
        echo -e "${YELLOW}Kallisto scripts completed.${NC}"
        
    fi
    
    
    if [ $align_mode = "hisat2" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        echo -e ""
        echo -e "Generating HISAT2 scripts for FASTQ alignment and processing...."
        
        cp ./project_payload/project_prepare_hisat2_scripts.R ${cluster_scripts_loc}/prepare_hisat2_scripts.R
        cp ./project_payload/project_hisat2_script_header.txt ${cluster_scripts_loc}/project_hisat2_script_header.txt
        
        ${RFolder}/Rscript ${cluster_scripts_loc}/prepare_hisat2_scripts.R
        
        echo -e "${YELLOW}HISAT scripts completed.${NC}"
        echo -e ""
        
        
    fi
    
    
    if [ $align_mode = "star" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        echo -e ""
        echo -e "Generating STAR scripts for FASTQ alignment and processing...."
        
        cp ./project_payload/project_prepare_star_scripts.R ${cluster_scripts_loc}/prepare_star_scripts.R
        cp ./project_payload/project_star_script_header.txt ${cluster_scripts_loc}/project_star_script_header.txt
        
        ${RFolder}/Rscript ${cluster_scripts_loc}/prepare_star_scripts.R
        
        echo -e "${YELLOW}STAR scripts completed.${NC}"
        echo -e ""
        
        
    fi
    
    
    
    if [ $align_mode = "star-notrim" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        echo -e ""
        echo -e "Generating STAR scripts for FASTQ alignment and processing...."
        
        cp ./project_payload/project_prepare_star_scripts_notrim.R ${cluster_scripts_loc}/prepare_star_scripts_notrim.R
        cp ./project_payload/project_star_script_header.txt ${cluster_scripts_loc}/project_star_script_header.txt
        
        ${RFolder}/Rscript ${cluster_scripts_loc}/prepare_star_scripts_notrim.R
        
        echo -e "${YELLOW}STAR scripts completed.${NC}"
        echo -e ""
        
        
    fi
    
    
    if [ $align_mode = "salmon" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        echo -e ""
        echo -e "Generating Salmon pseudo alignent of processed FASTQ files...."
        
        
        cp ./project_payload/project_prepare_salmon_scripts.R ${cluster_scripts_loc}/prepare_salmon_scripts.R
        cp ./project_payload/project_star_script_header.txt ${cluster_scripts_loc}/project_star_script_header.txt
        
        ${RFolder}/Rscript ${cluster_scripts_loc}/prepare_salmon_scripts.R
        
        echo -e "${YELLOW}Salmon scripts completed.${NC}"
        echo -e ""
        
        
    fi
    
    
    
    if [ $align_mode != "kallisto" ] && [ $align_mode != "hisat2" ] && [ $align_mode != "star" ] && [ $align_mode != "star-notrim" ] && [ $align_mode != "salmon" ]  ; then
        echo -e ""
        echo -e "${RED}No alignment mode specified.${NC}"
        echo -e ""
        echo -e "     Please specify an alignment mode for the RNA-seq data."
        echo -e "     Usage: ${YELLOW}--align ${YELLOW}<kallisto/star/star-notrim/bowtie2/hisat2/salmon>${NC}"
        echo -e ""
        exit 1
    fi
    
    
    
    
fi




###creating hisat2 index

#check index present first

if [ $run_mode = "--index" ] ; then
    
    index_mode="$2"
    
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    
    
    if [ -z $index_mode ] ; then
        echo -e ""
        echo -e "${RED}No INDEX mode specified.${NC}"
        echo -e ""
        echo -e "     Please specify the mode of Index creation required."
        echo -e "     Usage: ${YELLOW}--index <bowtie2/star/hisat2/kallisto>${NC}"
        echo -e ""
        exit 1
    fi
    
    
    if [ $index_mode = "hisat2" ] ; then
        
        echo -e "Entering HISAT2 Index mode...."
        
        if [ $sample_species = "human" ] ; then
            
            echo -e "Species: Human"
            echo -e "Checking index already present ?"
            
            if [ -e ${hg38_Ensembl_hisat2_index_loc} ] ; then
                
                echo -e "${RED}HISAT2 index for hg38 already created..${NC}"
                exit 1
                
            fi
            
            echo -e "Index not found.. Submitting hisat2 indexing for human hg38 genome..."
            
            #cp ./project_payload/project_create_index_hisat2.sh ${cluster_scripts_loc}/create_index_hisat2.sh
            
            echo -e "Moving project_payload create_index_hisat2.sh script to ${cluster_scripts_loc}"
            cat ./project_payload/project_create_index_hisat2.sh  | sed -e "s@PROJECTSCRIPTOUTPUT@$cluster_output_loc@g"   > ${cluster_scripts_loc}/create_index_hisat2.sh
            cat  ${cluster_scripts_loc}/create_index_hisat2.sh  | sed -e "s@PROJECTSCRIPTOUTPUT@$cluster_output_loc@g"   > ${cluster_scripts_loc}/create_index_hisat2.sh
            cat  ${cluster_scripts_loc}/create_index_hisat2.sh  | sed -e "s@PROJECTLOCATION@$project_data_loc@g"   > ${cluster_scripts_loc}/create_index_hisat2.sh
        fi
    fi
    
fi



###create stringtie gft outputs from hisat2 alignments

#

if [ $run_mode = "--stringtie" ] ; then
    
    stringtie_mode="$2"
    
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    
    
    
    if [ -z $stringtie_mode ] ; then
        echo -e ""
        echo -e "${RED}No STRINGTIE mode specified.${NC}"
        echo -e ""
        echo -e "     Please specify the mode of annotation with STRINGTIE"
        echo -e "     Usage: ${YELLOW}--stringtie <GTF/denovo/merge/abundance>${NC}"
        echo -e ""
        exit 1
    fi
    
    if [ $stringtie_mode = "GTF" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        echo -e ""
        echo -e "Generating STRINGTIE GTF guided scripts for BAM processing and transcript counting...."
        
        cp ./project_payload/project_prepare_stringtie-gtf_scripts.R ${cluster_scripts_loc}/prepare_stringtie-gtf_scripts.R
        cp ./project_payload/project_kallisto_script_header.txt ${cluster_scripts_loc}/project_kallisto_script_header.txt
        
        ${RFolder}/Rscript ${cluster_scripts_loc}/prepare_stringtie-gtf_scripts.R
        
        echo -e "${YELLOW}STRINGTIE GTF GUIDED scripts completed.${NC}"
        echo -e ""
        
        
    fi
    
    
    if [ $stringtie_mode = "denovo" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        echo -e ""
        echo -e "Generating STRINGTIE (de novo mode) scripts for BAM processing and transcript counting...."
        
        cp ./project_payload/project_prepare_stringtie-denovo_scripts.R ${cluster_scripts_loc}/prepare_stringtie-denovo_scripts.R
        cp ./project_payload/project_kallisto_script_header.txt ${cluster_scripts_loc}/project_kallisto_script_header.txt
        
        ${RFolder}/Rscript ${cluster_scripts_loc}/prepare_stringtie-denovo_scripts.R
        
        echo -e "${YELLOW}STRINGTIE (de novo mode) scripts completed.${NC}"
        echo -e ""
        
        
    fi

    if [ $stringtie_mode = "abundance" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        echo -e ""
        echo -e "Generating STRINGTIE Abundance counting scripts for BAM processing from merged Stringtie GTF...."
        
        cp ./project_payload/project_prepare_stringtie-abundance_scripts.R ${cluster_scripts_loc}/prepare_stringtie-abundance_scripts.R
        cp ./project_payload/project_kallisto_script_header.txt ${cluster_scripts_loc}/project_kallisto_script_header.txt
        
        ${RFolder}/Rscript ${cluster_scripts_loc}/prepare_stringtie-abundance_scripts.R
        
        echo -e "${YELLOW}STRINGTIE ABUNDANCE scripts completed.${NC}"
        echo -e ""
        
        
    fi
    
    
    
    
    if [ $stringtie_mode = "merge" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        echo -e ""
        echo -e "Generating STRINGTIE MERGED GTF files from sample GTF files...."
        
        echo [`date +"%Y-%m-%d %H:%M:%S"`] ""
        find ${stringtie_loc} | grep ".gtf" > ${stringtie_loc}/stringtie_mergelist.txt
        
        ##handle what species GTF is being used
        if [ $sample_species == zebrafish ]; then
            echo -e "Zebrafish GTF selected"
            if [ $sample_build == GRCz11 ]; then
                echo -e "GRCZ11 Build"
                GTFFILE=${ZF11_Ensembl_GTF_loc}
            else
                echo -e "GRCz10 Build"
                GTFFILE=${ZF_Ensembl_GTF_loc}
            fi
            
        else
            echo -e "No GTF selected"
            exit 1
        fi
        
        ${stringtieFolder}/stringtie --merge -p 1 -G  ${GTFFILE} -o ${ballgown_loc}/stringtie_merged.gtf ${stringtie_loc}/stringtie_mergelist.txt
        
        echo -e "${YELLOW}STRINGTIE GTF merging complete.${NC}"
        echo -e ""
        
        
    fi
    
    
fi




##########PREPARE BAM PROCESSING SCRIPTS
if [ $run_mode = "--bam_process" ] ; then
    
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    
    
    echo -e ""
    echo -e "Process unsorted BAM alignments into sorted and indexed...."
    
    #cp ./project_payload/project_prepare_bam_process_scripts.sh ${cluster_scripts_loc}/project_prepare_bam_process_scripts.sh
    cat ./project_payload/project_prepare_bam_process_scripts.sh | sed -e "s@PROJECTLOCATION@$project_data_loc@g"   > ${cluster_scripts_loc}/project_prepare_bam_process_scripts.sh
    
    
    cat ./project_payload/bam_process_.sh | sed -e "s@CHANGETHISFORSCRIPTERROR@$cluster_output_loc@g"   > ${cluster_scripts_loc}/bam_process_.sh
    
    
    #cp ./project_payload/bam_process_.sh ${cluster_scripts_loc}/bam_process_.sh
    
    bash ${cluster_scripts_loc}/project_prepare_bam_process_scripts.sh ${project_data_loc}/${project_code}_samples.tab
    
    echo -e "${YELLOW}Creation of BAM processing scripts completed.${NC}"
    echo -e ""
    
    
    #fi
    
    
    
    
fi


##########VALIDATE BAM FILES
if [ $run_mode = "--bam_validate" ] ; then
    
    validate_mode="$2"
    
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    
    if [ -z $validate_mode ] ; then
        echo -e ""
        echo -e "${RED}No BAM alignment type specified.${NC}"
        echo -e ""
        echo -e "     Please specify the BAM files to validate"
        echo -e "     Usage: ${YELLOW}--bam_validate <hisat2/star>${NC}"
        echo -e ""
        exit 1
    fi
    
    if [ $validate_mode = "hisat2" ] ; then
        
        echo -e ""
        echo -e "Validating HISAT2 aligned BAM files for inconsistencies...."
        find ${bam_hisat_loc} -type f -name "*.bam" -exec ${samtoolsFolder}/samtools quickcheck -v {} \;
        echo -e "${YELLOW}Validation complete.${NC}"
        echo -e ""
    fi
    
    if [ $validate_mode = "star" ] ; then
        
        echo -e ""
        echo -e "Validating STAR aligned BAM files for inconsistencies...."
        find ${bam_star_loc} -type f -name "*.bam" -exec ${samtoolsFolder}/samtools quickcheck -v {} \;
        echo -e "${YELLOW}Validation complete.${NC}"
        echo -e ""
    fi
    
fi





##########PREPARE HTSEQCOUNT SCRIPT KEEPING DUPS
if [ $run_mode = "--counts_htseq" ] ; then
    
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    
    
    echo -e ""
    #echo -e "Generating count files using htseq-count keeping duplicates...."
    echo -e "REDACTED\n"
    #cat ./project_payload/project_prepare_htseq_counts_keepdups_scripts.sh | sed -e "s@PROJECTLOCATION@$project_data_loc@g"   > ${cluster_scripts_loc}/project_prepare_htseq_counts_keepdups_scripts.sh
    
    #bash ${cluster_scripts_loc}/project_prepare_htseq_counts_keepdups_scripts.sh
    
fi


##########PREPARE FEATURECOUNTS SCRIPT KEEPING DUPS
if [ $run_mode = "--counts_fc" ] ; then
    
    
    fc_mode="$2"
    
    
    if [ -z $fc_mode ] ; then
        echo -e ""
        echo -e "${RED}No BAM mode specified.${NC}"
        echo -e ""
        echo -e "     Please specify the alignment files for analysis with featureCounts."
        echo -e "     Usage: ${YELLOW}--counts_fc <hisat2/star>${NC}"
        echo -e ""
        exit 1
    fi
    
    
    if [ $fc_mode = "hisat2" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        
        echo -e ""
        echo -e "Generating master count files from HISAT2 BAM alignments using featurecounts keeping duplicates....\n"
        
        cp ./project_payload/prepare_featurecounts.r   ${cluster_scripts_loc}/prepare_featurecounts.r
        
        ${RFolder}/Rscript ${cluster_scripts_loc}/prepare_featurecounts.r --bams=hisat2
        echo -e "${YELLOW}Script completed.${NC}"
        echo -e ""
    fi
    
    if [ $fc_mode = "star" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        
        echo -e ""
        echo -e "Generating master count files from STAR BAM alignments using featureCounts keeping duplicates....\n"
        
        cp ./project_payload/prepare_featurecounts.r   ${cluster_scripts_loc}/prepare_featurecounts.r
        cp ./project_payload/project_hisat2_script_header.txt  ${cluster_scripts_loc}/project_hisat2_script_header.txt
        
        ${RFolder}/Rscript ${cluster_scripts_loc}/prepare_featurecounts.r --bams=star
        echo -e "${YELLOW}Script completed.${NC}"
        echo -e ""
    fi
    
    
    if [ $fc_mode != "hisat2" ] && [ $fc_mode != "star" ]   ; then
        echo -e ""
        echo -e "${RED}No BAM alignment type specified.${NC}"
        echo -e ""
        echo -e "     Please specify the aligned BAM file type for counts."
        echo -e "     Usage: ${YELLOW}--counts_fc ${YELLOW}<hisat2/star>${NC}"
        echo -e ""
        exit 1
    fi
    
    
    
    
fi







##########PREPARE QORTS ANALYSIS SCRIPTS

if [ $run_mode = "--qorts" ] ; then
    
    qorts_mode="$2"
    
    
    if [ -z $qorts_mode ] ; then
        echo -e ""
        echo -e "${RED}No QoRTs mode specified.${NC}"
        echo -e ""
        echo -e "     Please specify the type of analysis required from QoRTs."
        echo -e "     Usage: ${YELLOW}--qorts <metrics/size/noveljunc>${NC}"
        echo -e ""
        exit 1
    fi
    
    
    if [ $qorts_mode = "metrics" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        
        
        echo -e ""
        echo -e "Generating QoRTs analysis files ...."
        
        cat ./project_payload/project_prepare_qorts_scripts.sh | sed -e "s@PROJECTLOCATION@$project_data_loc@g"   > ${cluster_scripts_loc}/project_prepare_qorts_scripts.sh
        
        bash ${cluster_scripts_loc}/project_prepare_qorts_scripts.sh
        
    fi
    
    
    if [ $qorts_mode = "noveljunc" ] ; then
        
        config_file=./project.config
        server_file=./server.config
        set -o allexport
        source $config_file
        source $server_file
        set +o allexport
        
        
        
        echo -e ""
        echo -e "Generating QoRTs analysis files using NOVEL JUNCTION analysis ...."
        
        cat ./project_payload/project_prepare_qorts_noveljunc_scripts.sh | sed -e "s@PROJECTLOCATION@$project_data_loc@g"   > ${cluster_scripts_loc}/project_prepare_qorts_noveljunc_scripts.sh
        
        bash ${cluster_scripts_loc}/project_prepare_qorts_noveljunc_scripts.sh
        
    fi
    
fi



##########PREPARE METRICS REPORT GENERATION
if [ $run_mode = "--metrics" ] ; then
    
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    NC='\033[0m' # No Color
    
    met_mode="$2"
    
    
    if [ -z $met_mode ] ; then
        echo -e ""
        echo -e "${RED}No metrics mode specified.${NC}"
        echo -e ""
        echo -e "     Please specify the type of analysis required."
        echo -e "     Usage: ${YELLOW}--metrics <qualimap/size/noveljunc>${NC}"
        echo -e ""
        exit 1
    fi
    
    if [ $met_mode = "qualimap" ] ; then
        metquali_mode="$3"
        echo $metquali_mode
        if [ -z $metquali_mode ] ; then
            echo -e ""
            echo -e "${RED}No Qualimap BAM type specified.${NC}"
            echo -e ""
            echo -e "     Please specify the BAM file type to be assessed."
            echo -e "     Usage: ${YELLOW}--metrics qualimap <hisat2/star>${NC}"
            echo -e ""
            exit 1
            
        fi
        
        
        if [ $metquali_mode = "star" ] ; then
            
            #CREATE LISTING OF BAM FILES FOR COUNTS
            echo -e "Discovering all BAM files, aligned with STAR, for Qualimap analysis.."
            echo ""
            cd ${bam_star_loc}
            find -type f -name '*unique.bam' -exec basename {} \; | sed -e 's/.unique.bam//g' > ${bam_star_loc}/bam_files_for_counts.txt
            #SET FILENAME list for analysis
            input_name=${bam_star_loc}/bam_files_for_counts.txt
            echo "Total files found:"
            cat ${input_name} | wc -l
            echo ""
            
            echo ""
            echo -e "${YELLOW}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
            echo -e "Creating bash script for QUALIMAP analysis of BAMs (STAR mode): ${RED}qualimap_${file_name}.sh${NC}"
            echo -e "${YELLOW}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
            echo -e ""
            
            
            ##handle what species GTF is being used
            if [ $sample_species == zebrafish ]; then
                echo -e "Zebrafish GTF selected"
                if [ $sample_build == GRCz11 ]; then
                    echo -e "GRCz11 Build"
                    GTFFILE=${ZF11_Ensembl_GTF_loc}
                else
                    echo -e "GRCz10 Build"
                    GTFFILE=${ZF_Ensembl_GTF_loc}
                fi
            fi
            
            if [ $sample_species == human ] ; then
                echo -e "Human GTF selected"
                if [ $sample_build == hg38 ] ; then
                    echo -e "GRCh38 build information"
                    GTFFILE=${hg38_Ensembl_GTF_loc}
                fi
            fi
            
            #else
            #	echo -e "No GTF selected"
            #	exit 1
            #fi
            
            
            while IFS='' read -r line
            do
                file_name="$line"
                echo -e "Adding command for filename read from file - ${RED}${file_name}${NC}"
                
                mkdir -p ${qualimap_reports}/star/${file_name}
                
                echo "#$ -l h_vmem=23G" > ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "#$ -l tmem=23G" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "#$ -l h_rt=3:0:0" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                #echo "#$ -pe smp 1" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "#$ -j y" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "#$ -cwd" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "#$ -l tscratch=100G" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "#$ -o ${cluster_output_loc}" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "#$ -e ${cluster_output_loc}" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "#$ -wd ${cluster_output_loc}" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "#$ -S /bin/bash" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "export TMP_DIR=/scratch0/smgxnow/qualimap" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "export TMPDIR=/scratch0/smgxnow/qualimap" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "export JAVA_HOME=${javaFolder}" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "export _JAVA_OPTIONS='-Djava.io.tmpdir=/scratch0/smgxnow/qualimap'" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "export JAVA_OPTIONS='-Djava.io.tmpdir=/scratch0/smgxnow/qualimap'" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "export _JAVA_OPTIONS=-Djava.io.tmpdir=/scratch0/smgxnow/qualimap" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "export JAVA_OPTIONS=-Djava.io.tmpdir=/scratch0/smgxnow/qualimap" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "export PATH=$PATH:${javaFolder}"  >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "mkdir -p /scratch0/smgxnow/qualimap" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                
                if [ $sample_paired == TRUE ] ; then
                    echo -e "Paired End reads detected. Flag set"
                    qualimap_paired_flag="-pe"
                else
                    qualimap_paired_flag=""
                fi
                
                if [ $sample_stranded == TRUE ] ; then
                    echo -e "Stranded information detected. Flag set"
                    qualimap_stranded_flag=${sample_strandedqualimap}
                else
                    qualimap_stranded_flag="non-strand-specific"
                    
                fi
                
                echo "${qualimapFolder}/qualimap rnaseq --java-mem-size=15G ${qualimap_paired_flag} -p ${qualimap_stranded_flag} -bam ${bam_star_loc}/${file_name}/${file_name}.unique.bam -gtf ${GTFFILE} -outdir ${qualimap_reports}/star/${file_name}  2>>${cluster_scripts_loc}/qualimap_star_error.log" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo "" >> ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                echo -e "${YELLOW}Submitting job to cluster......${NC}"
                
                qsub ${cluster_scripts_loc}/qualimap_star_${file_name}.sh
                
            done < "$input_name"
            
        fi
        
        if [ $metquali_mode = "hisat2" ] ; then
            
            #CREATE LISTING OF BAM FILES FOR COUNTS
            echo -e "Discovering all BAM files, aligned with HISAT2, for Qualimap analysis.."
            echo ""
            cd ${bam_hisat_loc}
            find -type f -name '*unique.bam' -exec basename {} \; | sed -e 's/.unique.bam//g' > ${bam_hisat_loc}/bam_files_for_counts.txt
            #SET FILENAME list for analysis
            input_name=${bam_hisat_loc}/bam_files_for_counts.txt
            echo "Total files found:"
            cat ${input_name} | wc -l
            echo ""
            
            echo ""
            echo -e "${YELLOW}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
            echo -e "Creating bash script for QUALIMAP analysis of BAMs (HISAT2 mode): ${RED}qualimap_${file_name}.sh${NC}"
            echo -e "${YELLOW}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
            echo -e ""
            
            
            ##handle what species GTF is being used
            if [ $sample_species == zebrafish ]; then
                echo -e "Zebrafish GTF selected"
                if [ $sample_build == GRCz11 ]; then
                    echo -e "GRCZ11 Build"
                    GTFFILE=${ZF11_Ensembl_GTF_loc}
                else
                    echo -e "GRCz10 Build"
                    GTFFILE=${ZF_Ensembl_GTF_loc}
                fi
            fi
            
            if [ $sample_species == human ] ; then
                echo -e "Human GTF selected"
                if [ $sample_build == hg38 ] ; then
                    echo -e "GRCh38 build information"
                    GTFFILE=${hg38_Ensembl_GTF_loc}
                fi
            fi
            
            #else
            #	echo -e "No GTF selected"
            #	exit 1
            #fi
            
            
            while IFS='' read -r line
            do
                file_name="$line"
                echo -e "Adding command for filename read from file - ${RED}${file_name}${NC}"
                
                mkdir -p ${qualimap_reports}/hisat2/${file_name}
                
                echo "#$ -l h_vmem=23G" > ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "#$ -l tmem=23G" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "#$ -l h_rt=3:0:0" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                #echo "#$ -pe smp 1" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "#$ -j y" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "#$ -cwd" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "#$ -l tscratch=100G" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "#$ -o ${cluster_output_loc}" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "#$ -e ${cluster_output_loc}" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "#$ -wd ${cluster_output_loc}" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "#$ -S /bin/bash" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "export TMP_DIR=/scratch0/smgxnow/qualimap" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "export TMPDIR=/scratch0/smgxnow/qualimap" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "export JAVA_HOME=${javaFolder}" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "export _JAVA_OPTIONS='-Djava.io.tmpdir=/scratch0/smgxnow/qualimap'" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "export JAVA_OPTIONS='-Djava.io.tmpdir=/scratch0/smgxnow/qualimap'" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "export _JAVA_OPTIONS=-Djava.io.tmpdir=/scratch0/smgxnow/qualimap" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "export JAVA_OPTIONS=-Djava.io.tmpdir=/scratch0/smgxnow/qualimap" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "export PATH=$PATH:${javaFolder}"  >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "mkdir -p /scratch0/smgxnow/qualimap" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                
                if [ $sample_paired == TRUE ] ; then
                    echo -e "Paired End reads detected. Flag set"
                    qualimap_paired_flag="-pe"
                else
                    qualimap_paired_flag=""
                fi
                
                if [ $sample_stranded == TRUE ] ; then
                    echo -e "Stranded information detected. Flag set"
                    qualimap_stranded_flag=${sample_strandedqualimap}
                else
                    qualimap_stranded_flag="non-strand-specific"
                    
                fi
                
                
                echo "${qualimapFolder}/qualimap rnaseq --java-mem-size=9G ${qualimap_paired_flag} -p ${qualimap_stranded_flag} -bam ${bam_hisat_loc}/${file_name}/${file_name}.unique.bam -gtf ${GTFFILE} -outdir ${qualimap_reports}/hisat2/${file_name}  2>>${cluster_scripts_loc}/qualimap_hisat2_error.log" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo "" >> ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                echo -e "${YELLOW}Submitting job to cluster......${NC}"
                
                qsub ${cluster_scripts_loc}/qualimap_hisat_${file_name}.sh
                
            done < "$input_name"
            
        fi
        
    fi
    
fi



##########MAJIQ ANALYSIS
if [ $run_mode = "--majiq" ] ; then
    
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    NC='\033[0m' # No Color
    
    majiq_mode="$2"
    
    
    if [ -z $majiq_mode ] ; then
        echo -e ""
        echo -e "${RED}No MAJIQ mode specified.${NC}"
        echo -e ""
        echo -e "     Please specify the type of analysis required."
        echo -e "     Usage: ${YELLOW}--majiq <build/quant/viola>${NC}"
        echo -e ""
        exit 1
    fi
    
    if [ $majiq_mode = "viola" ] ; then
        majiqviola_mode="$3"
        echo -e "Viola mode: conditions $majiqviola_mode"
        if [ -z $majiqviola_mode ] ; then
            echo -e ""
            echo -e "${RED}No MAJIQ Viola BAM type specified.${NC}"
            echo -e ""
            echo -e "     Please specify the comparisons to be assessed."
            echo -e "     Usage: ${YELLOW}--majiq viola <cond1/cond2>${NC}"
            echo -e ""
            exit 1
        fi
        ${majiqFolder}/viola ${majiq_data}/${majiqviola_mode}
        
    fi
    
    
    
    if [ $majiq_mode = "build" ] ; then
        majiqbuild_mode="$3"
        echo $majiqbuild_mode
        if [ -z $majiqbuild_mode ] ; then
            echo -e ""
            echo -e "${RED}No MAJIQ build BAM type specified.${NC}"
            echo -e ""
            echo -e "     Please specify the BAM file type to be assessed."
            echo -e "     Usage: ${YELLOW}--majiq build <hisat2/star>${NC}"
            echo -e ""
            exit 1
        fi
        
        if [ $majiqbuild_mode = "star" ] ; then
            
            config_file=./project.config
            server_file=./server.config
            set -o allexport
            source $config_file
            source $server_file
            set +o allexport
            RED='\033[0;31m'
            YELLOW='\033[0;33m'
            NC='\033[0m' # No Color
            
            #CREATE LISTING OF BAM FILES FOR COUNTS
            echo -e "Discovering all BAM files, aligned with STAR, for MAJIQ analysis.."
            echo ""
            cd ${bam_star_loc}
            find -type f -name '*unique.bam' -exec basename {} \; | sed -e 's/.unique.bam//g' > ${bam_star_loc}/bam_files_for_majiqbuild.txt
            #SET FILENAME list for analysis
            input_name=${bam_star_loc}/bam_files_for_majiqbuild.txt
            echo "Total files found:"
            cat ${input_name} | wc -l
            echo ""
            
            echo ""
            echo -e "${YELLOW}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
            echo -e "Creating bash script for MAJIQ BUILD of BAMs (STAR mode): ${RED}majiq_build_star.sh${NC}"
            echo -e "${YELLOW}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
            echo -e ""
            
            ##handle what species GFF is being used
            if [ $sample_species == zebrafish ]; then
                echo -e "Zebrafish GFF selected"
                if [ $sample_build == GRCz11 ]; then
                    echo -e "GRCZ11 Build"
                    GFFFILE=${ZF11_Ensembl_GFF_loc}
                else
                    echo -e "GRCz10 Build"
                    GFFFILE=${ZF_Ensembl_GFF_loc}
                fi
            fi
            
            if [ $sample_species == human ] ; then
                echo -e "Human GFF selected"
                if [ $sample_build == hg38 ] ; then
                    echo -e "GRCh38 build information"
                    GFFFILE=${hg38_Ensembl_GFF_loc}
                fi
            fi
            
            #else
            #	echo -e "No GTF selected"
            #	exit 1
            #fi
            
            
            echo -e "Creating MAJIQ BUILD master script - ${RED}majiq_build_star.sh${NC}"
            
            mkdir -p ${project_data_loc}/majiq/star/build
            
            echo "#$ -l h_vmem=23G" > ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -l tmem=23G" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -l h_rt=47:0:0" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -pe smp 4" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -j y" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -R y" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -cwd" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -m beasn" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -M smgxnow@ucl.ac.uk" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -l tscratch=100G" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -o ${cluster_output_loc}" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -e ${cluster_output_loc}" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -wd ${cluster_output_loc}" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "#$ -S /bin/bash" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "export TMP_DIR=/scratch0/smgxnow/majiq" >>  ${cluster_scripts_loc}/majiq_build_star.sh
            echo "export TMPDIR=/scratch0/smgxnow/majiq" >>  ${cluster_scripts_loc}/majiq_build_star.sh
            echo "export PATH=$PATH:${javaFolder}"  >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "export PATH=${pythonFolder}:$PATH" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "mkdir -p /scratch0/smgxnow/majiq" >> ${cluster_scripts_loc}/majiq_build_star.sh
            
            echo "${majiqFolder}/majiq build ${GFFFILE} -o ${project_data_loc}/majiq/star/build -c  ${project_data_loc}/majiq/majiq_build_star_config.ini -j 4" >> ${cluster_scripts_loc}/majiq_build_star.sh
            echo "" >> ${cluster_scripts_loc}/majiq_build_star.sh
            
            echo -e ""
            echo -e "Creating CONFIG.INI file for MAJIQ BUILD."
            echo -e ""
            
            ${RFolder}/Rscript ${cluster_scripts_loc}/prepare_majiq_build_config.r --bams=star
            
            echo -e "${YELLOW}Submitting job to cluster......${NC}"
            
            qsub ${cluster_scripts_loc}/majiq_build_star.sh
            
            
        fi
        
        
        if [ $majiqbuild_mode = "hisat2" ] ; then
            
            config_file=./project.config
            server_file=./server.config
            set -o allexport
            source $config_file
            source $server_file
            set +o allexport
            RED='\033[0;31m'
            YELLOW='\033[0;33m'
            NC='\033[0m' # No Color
            
            #CREATE LISTING OF BAM FILES FOR COUNTS
            echo -e "Discovering all BAM files, aligned with HISAT2, for MAJIQ analysis.."
            echo ""
            cd ${bam_hisat_loc}
            find -type f -name '*unique.bam' -exec basename {} \; | sed -e 's/.unique.bam//g' > ${bam_hisat_loc}/bam_files_for_majiqbuild.txt
            #SET FILENAME list for analysis
            input_name=${bam_hisat_loc}/bam_files_for_majiqbuild.txt
            echo "Total files found:"
            cat ${input_name} | wc -l
            echo ""
            
            echo ""
            echo -e "${YELLOW}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
            echo -e "Creating bash script for MAJIQ BUILD of BAMs (HISAT2 mode): ${RED}majiq_build_hisat2.sh${NC}"
            echo -e "${YELLOW}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
            echo -e ""
            
            ##handle what species GFF is being used
            if [ $sample_species == zebrafish ]; then
                echo -e "Zebrafish GFF selected"
                if [ $sample_build == GRCz11 ]; then
                    echo -e "GRCZ11 Build"
                    GFFFILE=${ZF11_Ensembl_GFF_loc}
                else
                    echo -e "GRCz10 Build"
                    GFFFILE=${ZF_Ensembl_GFF_loc}
                fi
            fi
            
            if [ $sample_species == human ] ; then
                echo -e "Human GFF selected"
                if [ $sample_build == hg38 ] ; then
                    echo -e "GRCh38 build information"
                    GFFFILE=${hg38_Ensembl_GFF_loc}
                fi
            fi
            
            #else
            #	echo -e "No GTF selected"
            #	exit 1
            #fi
            
            
            echo -e "Creating MAJIQ BUILD master script - ${RED}majiq_build_hisat2.sh${NC}"
            
            mkdir -p ${project_data_loc}/majiq/hisat2/build
            
            echo "#$ -l h_vmem=23G" > ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -l tmem=23G" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -l h_rt=47:0:0" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -pe smp 4" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -j y" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -R y" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -cwd" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -m beasn" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -M smgxnow@ucl.ac.uk" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -l tscratch=100G" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -o ${cluster_output_loc}" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -e ${cluster_output_loc}" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -wd ${cluster_output_loc}" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "#$ -S /bin/bash" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "export TMP_DIR=/scratch0/smgxnow/majiq" >>  ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "export TMPDIR=/scratch0/smgxnow/majiq" >>  ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "export PATH=$PATH:${javaFolder}"  >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "export PATH=${pythonFolder}:$PATH" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "mkdir -p /scratch0/smgxnow/majiq" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            
            echo "${majiqFolder}/majiq build ${GFFFILE} -o ${project_data_loc}/majiq/hisat2/build -c  ${project_data_loc}/majiq/majiq_build_hisat2_config.ini -j 4" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            echo "" >> ${cluster_scripts_loc}/majiq_build_hisat2.sh
            
            echo -e ""
            echo -e "Creating CONFIG.INI file for MAJIQ BUILD."
            echo -e ""
            
            ${RFolder}/Rscript ${cluster_scripts_loc}/prepare_majiq_build_config.r --bams=hisat2
            
            echo -e "${YELLOW}Submitting job to cluster......${NC}"
            
            qsub ${cluster_scripts_loc}/majiq_build_hisat2.sh
            
            
            
        fi
        
        
        
        
    fi
    
fi


##########VARIANT CALLING PIPELINE
if [ $run_mode = "--call_variants" ] ; then
    
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    NC='\033[0m' # No Color
    
    callvar_mode="$2"
    
    
    if [ -z $callvar_mode ] ; then
        echo -e ""
        echo -e "${RED}No Variant Calling mode specified.${NC}"
        echo -e ""
        echo -e "     Please specify the type of analysis required."
        echo -e "     Usage: ${YELLOW}--call_variants <splitN/recal/callvar>${NC}"
        echo -e ""
        exit 1
    fi
    
    if [ $callvar_mode = "splitN" ] ; then
        splitNsample="$3"
        
        if [ -z $splitNsample ] ; then
            echo -e ""
            echo -e "${RED}No sample name specified.${NC}"
            echo -e ""
            echo -e "     Please specify the name of the SAMPLE to process."
            echo -e "     Usage: ${YELLOW}--call_variants splitN UM01_00_01${NC}"
            echo -e ""
            exit 1
        fi
        export JAVA_HOME=${javaFolder}
        export PATH=$PATH:${javaFolder}
        
        #CHECK SAMPLE exists
        
        echo -e ""
        echo -e "${RED}SAMPLE:${NC} ./${splitNsample}/${splitNsample}.unique.bam"
        echo -e ""
        echo "#$ -l h_vmem=15G" > ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -l tmem=15G" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -l h_rt=11:0:0" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -pe smp 4" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -j y" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -R y" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -cwd" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -m beasn" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -M smgxnow@ucl.ac.uk" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -l tscratch=100G" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -o ${cluster_output_loc}" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -e ${cluster_output_loc}" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -wd ${cluster_output_loc}" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "#$ -S /bin/bash" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "export TMP_DIR=/scratch0/smgxnow/gatk" >>  ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "export TMPDIR=/scratch0/smgxnow/gatk" >>  ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "export PATH=$PATH:${javaFolder}:${pythonFolder}"  >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "mkdir -p /scratch0/smgxnow/gatk" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        echo "export JAVA_HOME=${javaFolder}" >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        
        echo "${gatkFolder}/gatk --java-options '-Dsamjdk.compression_level=6'  SplitNCigarReads -R ${hg38_Ensembl_FAuncomp_loc} \
--tmp-dir /scratch0/smgxnow/gatk \
-I ${bam_star_loc}/${splitNsample}/${splitNsample}.unique.bam \
        -O ${bam_star_loc}/${splitNsample}/${splitNsample}.split.bam " >> ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        
        echo -e "${YELLOW}Submitting job to cluster......${NC}"
        
        qsub ${cluster_scripts_loc}/gatk_splitN_${splitNsample}.sh
        
        
    fi
    
    if [ $callvar_mode = "recal" ] ; then
        recalsample="$3"
        
        if [ -z $recalsample ] ; then
            echo -e ""
            echo -e "${RED}No sample name specified.${NC}"
            echo -e ""
            echo -e "     Please specify the name of the SAMPLE to process."
            echo -e "     Usage: ${YELLOW}--call_variants recal UM01_00_01${NC}"
            echo -e ""
            exit 1
        fi
        
        echo -e ""
        echo -e "${RED}SAMPLE:${NC} ./${recalsample}/${recalsample}.split.bam"
        echo -e ""
        echo "#$ -l h_vmem=15.9G" > ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -l tmem=15.9G" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -l h_rt=23:0:0" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -pe smp 4" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -j y" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -R y" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -cwd" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -m beasn" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -M smgxnow@ucl.ac.uk" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -l tscratch=100G" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -o ${cluster_output_loc}" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -e ${cluster_output_loc}" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -wd ${cluster_output_loc}" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "#$ -S /bin/bash" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "export TMP_DIR=/scratch0/smgxnow/gatk" >>  ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "export TMPDIR=/scratch0/smgxnow/gatk" >>  ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "export PATH=$PATH:${javaFolder}:${pythonFolder}"  >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "mkdir -p /scratch0/smgxnow/gatk" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "export JAVA_HOME=${javaFolder}" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        echo "export R_LIBS_USER={RlibFolder}" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        
        
        
        echo "${gatkFolder}/gatk  BaseRecalibrator -R ${hg38_Ensembl_FAuncomp_loc} \
--tmp-dir /scratch0/smgxnow/gatk \
-I ${bam_star_loc}/${recalsample}/${recalsample}.split.bam \
--known-sites ${hg38_recal_dbSNP} \
--known-sites ${hg38_recal_MILLS} \
--known-sites ${hg38_recal_1000G} \
        -O ${bam_star_loc}/${recalsample}/${recalsample}_recal_data.table  " >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        
        echo "${gatkFolder}/gatk --java-options '-Dsamjdk.compression_level=6'  ApplyBQSR \
--tmp-dir /scratch0/smgxnow/gatk \
-R ${hg38_Ensembl_FAuncomp_loc} \
-I ${bam_star_loc}/${recalsample}/${recalsample}.split.bam \
--bqsr-recal-file ${bam_star_loc}/${recalsample}/${recalsample}_recal_data.table \
        -O ${bam_star_loc}/${recalsample}/${recalsample}.recal.split.bam" >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        
        echo "${gatkFolder}/gatk  BaseRecalibrator -R ${hg38_Ensembl_FAuncomp_loc} \
--tmp-dir /scratch0/smgxnow/gatk \
-I ${bam_star_loc}/${recalsample}/${recalsample}.recal.split.bam \
--known-sites ${hg38_recal_dbSNP} \
--known-sites ${hg38_recal_MILLS} \
--known-sites ${hg38_recal_1000G} \
        -O ${bam_star_loc}/${recalsample}/${recalsample}_post_recal_data.table  " >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        
        echo "${gatkFolder}/gatk  AnalyzeCovariates  \
--tmp-dir /scratch0/smgxnow/gatk \
-before ${bam_star_loc}/${recalsample}/${recalsample}_recal_data.table \
-after ${bam_star_loc}/${recalsample}/${recalsample}_post_recal_data.table \
-csv ${bam_star_loc}/${recalsample}/${recalsample}_recalibration_plots.csv \
        -plots ${bam_star_loc}/${recalsample}/${recalsample}_recalibration_plots.pdf " >> ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        
        echo -e "${YELLOW}Submitting job to cluster......${NC}"
        
        qsub ${cluster_scripts_loc}/gatk_recal_${recalsample}.sh
        
    fi
    
    
    if [ $callvar_mode = "callvar" ] ; then
        callvarsample="$3"
        
        if [ -z $callvarsample ] ; then
            echo -e ""
            echo -e "${RED}No sample name specified.${NC}"
            echo -e ""
            echo -e "     Please specify the name of the SAMPLE to process."
            echo -e "     Usage: ${YELLOW}--call_variants callvar UM01_00_01${NC}"
            echo -e ""
            exit 1
        fi
        
        
        echo -e "${YELLOW}Creating call_variants job for sample: ./${callvarsample}/${callvarsample}${NC}"
        echo -e ""
        echo "#$ -l h_vmem=23.9G" > ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -l tmem=23.9G" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -l h_rt=72:0:0" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -pe smp 2" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -j y" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -R y" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -cwd" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -m beasn" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -M smgxnow@ucl.ac.uk" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -l tscratch=100G" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -o ${cluster_output_loc}" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -e ${cluster_output_loc}" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -wd ${cluster_output_loc}" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "#$ -S /bin/bash" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "export TMP_DIR=/scratch0/smgxnow/gatk" >>  ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "export TMPDIR=/scratch0/smgxnow/gatk" >>  ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "export PATH=$PATH:${javaFolder}:${pythonFolder}"  >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "export LD_LIBRARY_PATH=${pythonLibFolder}:$LD_LIBRARY_PATH" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "mkdir -p /scratch0/smgxnow/gatk" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        echo "export JAVA_HOME=${javaFolder}" >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        
        
        echo "${gatkFolder}/gatk  HaplotypeCaller -R ${hg38_Ensembl_FAuncomp_loc} \
--tmp-dir /scratch0/smgxnow/gatk \
-I ${bam_star_loc}/${callvarsample}/${callvarsample}.recal.split.bam \
-O ${bam_star_loc}/${callvarsample}/${callvarsample}.g.vcf.gz  \
--emit-ref-confidence GVCF \
-G StandardAnnotation \
-G AS_StandardAnnotation \
-bamout ${bam_star_loc}/${recalsample}/${callvarsample}.g.vcf.bam \
--create-output-bam-index  \
        --create-output-variant-index  " >> ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
        
        echo -e "${YELLOW}Submitting job to cluster......${NC}"
        qsub ${cluster_scripts_loc}/gatk_callvar_${callvarsample}.sh
    fi
    
    
    
    if [ $callvar_mode = "convert_gvcf2vcf" ] ; then
        convertsample="$3"
        
        if [ -z $convertsample ] ; then
            echo -e ""
            echo -e "${RED}No sample name specified.${NC}"
            echo -e ""
            echo -e "     Please specify the name of the SAMPLE to process."
            echo -e "     Usage: ${YELLOW}--call_variants convert_gvcf2vcf UM01_00_01${NC}"
            echo -e ""
            exit 1
        fi
        
        
        echo -e "${YELLOW}Converting gVCF to VCF: ./${convertsample}/${convertsample}${NC}"
        echo -e ""
        bcftools convert --gvcf2vcf ${bam_star_loc}/${convertsample}/${convertsample}.g.vcf.gz -O z -o ${bam_star_loc}/${convertsample}/${convertsample}.vcf --fasta-ref ${hg38_Ensembl_FAuncomp_loc}
        echo -e "Done."
        echo -e ""
    fi
    
    
    
fi

###PREPARE reference datasets from Ensembl

if [ $run_mode = "--get_ref" ] ; then
    echo ""
    echo "Checking options for downloading reference dataset from Ensembl.."
    echo ""
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    NC='\033[0m' # No Color
    
    ref_species="$2"
    ref_version="$3"
    
    if [ -z $ref_species ] ; then
        echo -e ""
        echo -e "${RED}No species specified. Checking available species..${NC}"
        echo -e ""
        cp ./project_payload/get_ensembl.py ${cluster_scripts_loc}/get_ensembl.py
        ${pythonFolder}/python ${scriptsFolder}/get_ref_species.py -l LIST
        echo -e "Please specify which species you require and version number."
        echo -e "${RED}Usage: RNAseq.sh --get_ref <species> <version>${NC}"
        exit 1
    fi
    
    if [ -z $ref_version ] ; then
        echo -e ""
        echo -e "${RED}No version number specified.${NC}"
        echo -e ""
        echo -e "Please specify which species you require and version number."
        echo -e "${RED}Usage: RNAseq.sh --get_ref <species> <version>${NC}"
        exit 1
    fi
    
    if [ ! -z $ref_species ]; then
        echo -e ""
        echo -e "${YELLOW}Downloading reference dataset from Ensembl for species: ${ref_species}${NC}"
        echo -e ""
        cp ./project_payload/get_ensembl.py ${cluster_scripts_loc}/get_ensembl.py
        ${pythonFolder}/python ${scriptsFolder}/get_ref_species.py --organism $ref_species --version $ref_version
        echo -e "Complete."
        exit 1
    fi
    
fi







##########  SANITY CHECK ON THE PROJECT SUPPORT DOCUMENTS EXISTINGS AND >0 BYTES
if [ $run_mode = "--sanity" ] ; then
    
    config_file=./project.config
    server_file=./server.config
    set -o allexport
    source $config_file
    source $server_file
    set +o allexport
    
    clear
    echo -e ""
    echo -e "In-house sanity checks"
    echo -e "${PURPLE}~${RED}~${PINK}~${YELLOW}~${GREEN}~${BLUE}~${NC}~${PURPLE}~${RED}~${PINK}~${YELLOW}~${GREEN}~${BLUE}~${NC}~${PURPLE}~${RED}~${PINK}~${YELLOW}~${GREEN}~${BLUE}~${NC}~${PURPLE}~${NC}"
    echo ""
    echo -e "Checking for file extensions of trimmed FASTQ files...."
    echo -e ""
    echo -e "Location: ${YELLOW}${fastq_trimmed_loc}${NC}"
    file_ext=$(find ${fastq_trimmed_loc} -type f -name "*.gz"  | awk -F. '{print $2"."$3}' | uniq)
    echo -e "File extension: ${RED}${file_ext}${NC}"
    nos_files=$(find ${fastq_trimmed_loc} -type f -name "*.gz"  | awk -F. '{print $2"."$3}' | wc -l)
    echo -e "${NC}Total Number of files: ${RED}${nos_files}${NC}"
    echo -e "${NC}"
    nos_R1=$(find ${fastq_trimmed_loc} -type f -name "*R1*.gz"   | wc -l)
    nos_R2=$(find ${fastq_trimmed_loc} -type f -name "*R2*.gz"   | wc -l)
    echo -e "Number of First Read Files: ${RED}${nos_R1}${NC}"
    echo -e "Number of Second Read Files: ${RED}${nos_R2}${NC}"
    
    if [ ${nos_R2} > 0 ] ; then
        echo -e ""
        echo -e "${GREEN}Paired End Mode${NC} of Analysis/Data found."
    fi
    
    if [ ${nos_R1} = 0 ] ; then
        echo -e ""
        echo -e "No Read1 files found."
        exit 1
    fi
    
    if [ ${nos_R1} -g 0 -a ${nos_R2} = 0 ] ; then
        echo -e ""
        echo -e "${GREEN}Single End Mode${NC} of Analysis/Data found."
        
    fi
    
    if [ ${nos_R2} = 0 ] ; then
        echo -e ""
        echo -e "No Read2 files found."
        exit 1
    fi
    
    
    ##check server configuration NEEDS REWORKING
    
    while read -r dir; do
        dir2=$(echo $dir | sed 's/[^/]*\(.*\)/\1/')
        if [[ -d $dir2 ]]; then
            echo "Directory $dir2 exists"
        else
            echo "Dir $dir2 does not exist"
        fi
    done < ./server.config
    echo -e ""
    
    ##count number of lines in support files:
    echo -e ""
    
    nos_samples=$(cat ${project_data_loc}/${project_code}_samples.tab | wc -l)
    echo -e "Samples found in ${project_code}_samples.tab: ${RED}${nos_samples}${NC}"
    
    if [ ${nos_samples} = 0 ] ; then
        echo -e "No samples reported in ${project_code}_samples.tab. Please check support files."
        exit 1
    fi
    
    ##check files are not empty
    #${project_code}_support_trimmed.tab
    #${project_code}_support.tab
    #${project_code}_samples.tab
    #${project_code}_fastq_trimmed.tab
    #${project_code}_fastq_raw.tab
    
    echo ""
    echo -e "Checking all support files are present:-"
    echo ""
    
    if [ -e ${project_code}_support_trimmed.tab ] ; then
        echo -e "Trimmed support file: ${GREEN}OK${NC}"
    else
        echo -e "Trimmed support file: ${RED}NOT FOUND${NC}"
    fi
    
    if [ -e ${project_code}_support.tab ] ; then
        echo -e "Support file: ${GREEN}OK${NC}"
    else
        echo -e "Support file: ${RED}NOT FOUND${NC}"
    fi
    
    if [ -e ${project_code}_samples.tab ] ; then
        echo -e "Samples file: ${GREEN}OK${NC}"
    else
        echo -e "Samples file: ${RED}NOT FOUND${NC}"
    fi
    
    if [ -e ${project_code}_fastq_trimmed.tab ] ; then
        echo -e "FASTQ trimmed support file: ${GREEN}OK${NC}"
    else
        echo -e "FASTQ trimmed support file: ${RED}NOT FOUND${NC}"
    fi
    
    if [ -e ${project_code}_fastq_raw.tab ] ; then
        echo -e "FASTQ raw support file: ${GREEN}OK${NC}"
    else
        echo -e "FASTQ raw support file: ${RED}NOT FOUND${NC}"
    fi
    
    echo ""
    
fi





modes="--index --prepare_project --prepare_support --prepare_support_trim --help --version --sanity --qorts  --counts_htseq --counts-fc --fastqc --majiq --get_ref"

exit 0