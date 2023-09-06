version 1.0

task samtools_index {
	input {
		File bam_or_cram
		
		Int additional_disk = 1
		Int preemptible = 1
		Int memory = 8
	}
	Int disk_size = ceil(size(bam_or_cram), "GB") + additional_disk
	
	command <<<
	set -eux -o pipefail
	FILE_EXT=$(echo ~{bam_or_cram} | sed 's/.*\.//')
	if [ "$FILE_EXT" = "cram" ] || [ "$FILE_EXT" = "CRAM" ]
	then
		samtools index "~{bam_or_cram}" "~{bam_or_cram}.crai"
		mv "~{bam_or_cram}.crai" .
		rm "~{bam_or_cram}"
	elif [ "$FILE_EXT" = "bam" ] || [ "$FILE_EXT" = "BAM" ]
	then
		samtools index "~{bam_or_cram}" "~{bam_or_cram}.bai"
		mv "~{bam_or_cram}.bai" .
		rm "~{bam_or_cram}"
	else
		echo "Neither a bam nor a cram. Error."
		exit 1
	fi
	>>>
	
	runtime {
		docker: "ashedpotatoes/goleft-covstats:0.0.2"
		preemptible: preemptible
		disks: "local-disk " + disk_size + " HDD"
		memory: memory + "GB"
	}
	
	output {
		File bai_or_crai = glob(basename(bam_or_cram)+"*")[0]
	}
}

workflow Samtools_Index {
	input {
		Array[File] bams_or_crams
	}
	
	scatter(bam_or_cram in bams_or_crams) {
		call samtools_index {input: bam_or_cram = bam_or_cram}
	}
	
	output {
		Array[File] bais_or_crais = samtools_index.bai_or_crai
	}
}
