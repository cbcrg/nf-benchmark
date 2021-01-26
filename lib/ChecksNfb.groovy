/*
 * This file holds several functions used to perform nf-benchmark checks.
 */

class ChecksNfb {

    static void check_pipeline_config(params, log) {
        Map colors = Headers.log_colours(params.monochrome_logs)

        def config_file = new File (params.pipeline_config)
        if ( !config_file.exists() ) {
            log.info "=${colors.yellow}====================================================${colors.reset}=\n" +
                     "${colors.yellow}WARN: The module pipeline included `$params.pipeline`\n" +
                     "      does not declare any ${colors.white}'nextflow.config'${colors.reset}${colors.yellow} file.\n" +
                     "      You can include it at ${colors.white}`${params.path_to_pipelines}`${colors.yellow}.\n" +
                     "      or otherwise use ${colors.white}`--pipeline_config`${colors.yellow} to set its path.${colors.reset}\n" +
                     "=${colors.yellow}====================================================${colors.reset}="
        }        
    }

    static void check_profiles (params, workflow, log) {
        Map colors = Headers.log_colours(params.monochrome_logs)

        if ( workflow.profile.findAll('nfb-').size() != workflow.profile.minus('standard').tokenize( ',' ).size() ) {
            log.info "=${colors.yellow}====================================================${colors.reset}=\n" +
                     "${colors.yellow}WARN: Some of the selected profiles belong to the pipeline module.\n" +
                     "      Check that any parameter is overwritten.${colors.reset}\n" +
                     "=${colors.yellow}====================================================${colors.reset}=" 
        }
    }
}
