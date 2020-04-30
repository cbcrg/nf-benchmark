params.foo = ['Hello', 'Hallo']

process foo {
    //input:
    // val (foo_var)

    output:
    stdout()

    script:
    """
    echo "${params.foo} world"
    """
}
