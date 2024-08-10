"""Utility rules for pytest rules and macros"""

def _extra_pytest_args_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".txt")
    ctx.actions.write(
        output = output,
        content = json.encode(ctx.build_setting_value),
    )

    return [DefaultInfo(
        files = depset([output]),
    )]

extra_pytest_args = rule(
    doc = "A rule for providing additional arguments to pytest",
    implementation = _extra_pytest_args_impl,
    build_setting = config.string_list(flag = True),
)

def _pytest_entrypoint_wrapper_impl(ctx):
    output = ctx.outputs.out

    args = ctx.actions.args()
    args.add("--output", output)
    args.add("--entrypoint", ctx.file.entrypoint)

    ctx.actions.run(
        mnemonic = "PytestEntrypointSanitizer",
        outputs = [output],
        inputs = [ctx.file.entrypoint],
        arguments = [args],
        executable = ctx.executable._sanitizer,
    )

    return [DefaultInfo(
        files = depset([output]),
    )]

pytest_entrypoint_wrapper = rule(
    doc = "A rule for injecting ignore directives for common linters.",
    implementation = _pytest_entrypoint_wrapper_impl,
    attrs = {
        "entrypoint": attr.label(
            doc = "The pytest entrypoint.",
            mandatory = True,
            allow_single_file = True,
        ),
        "out": attr.output(
            doc = "The output file.",
            mandatory = True,
        ),
        "_sanitizer": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("//python/pytest/private:entrypoint_sanitizer"),
        ),
    },
)