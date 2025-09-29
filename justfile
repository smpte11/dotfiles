# Justfile for testing chezmoi templates
# Usage: just test

# Template files to test
templates := "run_onchange_00-install-packages.sh.tmpl empty_dot_gitconfig.tmpl dot_bashrc.tmpl dot_zshrc.tmpl"

# Seed data for different scenarios
seed-base := '--init --stdinisatty=false --promptString name="Test User" --promptString email="test@example.com"'
seed-linux := '--init --stdinisatty=false --promptString name="Test User" --promptString email="test@example.com"'
seed-work := '--init --stdinisatty=false --promptString name="Test User" --promptString email="test@example.com"'

# Test all templates with configurable output and seeding
test verbose="false" seeded="false":
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{seeded}}" == "true" ]]; then
        echo "🧪 Testing all templates with seed data..."
    else
        echo "🧪 Testing all templates..."
    fi
    for template in {{templates}}; do
        just _test-one "$template" "{{verbose}}" "{{seeded}}"
    done
    if [[ "{{seeded}}" == "true" ]]; then
        echo "🧪 Testing special scenarios..."
        just _test-one "run_onchange_00-install-packages.sh.tmpl" "{{verbose}}" "true" "linux"
        just _test-one "dot_zshrc.tmpl" "{{verbose}}" "true" "work"
    fi
    echo "✅ All template tests completed successfully!"

# Internal: Test a single template with scenario support
_test-one template verbose="false" seeded="false" scenario="base":
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{seeded}}" == "true" ]]; then
        if [[ "{{scenario}}" == "linux" ]]; then
            echo "🧪 Testing {{template}} with seed data (Linux/Bazzite)..."
        elif [[ "{{scenario}}" == "work" ]]; then
            echo "🧪 Testing {{template}} with seed data (work machine)..."
        else
            echo "🧪 Testing {{template}} with seed data..."
        fi
    else
        echo "🧪 Testing {{template}}..."
    fi
    
    if [[ "{{seeded}}" == "true" ]]; then
        case "{{scenario}}" in
            "linux")
                if [[ "{{verbose}}" == "true" ]]; then
                    chezmoi execute-template {{seed-linux}} < "{{template}}"
                else
                    chezmoi execute-template {{seed-linux}} < "{{template}}" > /dev/null
                fi
                ;;
            "work")
                if [[ "{{verbose}}" == "true" ]]; then
                    chezmoi execute-template {{seed-work}} < "{{template}}"
                else
                    chezmoi execute-template {{seed-work}} < "{{template}}" > /dev/null
                fi
                ;;
            *)
                if [[ "{{verbose}}" == "true" ]]; then
                    chezmoi execute-template {{seed-base}} < "{{template}}"
                else
                    chezmoi execute-template {{seed-base}} < "{{template}}" > /dev/null
                fi
                ;;
        esac
    else
        if [[ "{{verbose}}" == "true" ]]; then
            chezmoi execute-template < "{{template}}"
        else
            chezmoi execute-template < "{{template}}" > /dev/null
        fi
    fi
    
    if [[ "{{scenario}}" == "linux" ]]; then
        echo "✅ {{template}} (Linux/Bazzite) is valid"
    elif [[ "{{scenario}}" == "work" ]]; then
        echo "✅ {{template}} (work machine) is valid"
    else
        echo "✅ {{template}} is valid"
    fi

# Test individual template with flexible options
test-one template verbose="false" seeded="false" scenario="base":
    @just _test-one "{{template}}" "{{verbose}}" "{{seeded}}" "{{scenario}}"

# Quick syntax validation with optional seeding
check template="all" seeded="false":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "⚡ Quick syntax check..."
    if [[ "{{template}}" == "all" ]]; then
        for tmpl in {{templates}}; do
            echo -n "Checking $tmpl... "
            if [[ "{{seeded}}" == "true" ]]; then
                chezmoi execute-template {{seed-base}} < "$tmpl" >/dev/null 2>&1 && echo "✅" || echo "❌"
            else
                chezmoi execute-template < "$tmpl" >/dev/null 2>&1 && echo "✅" || echo "❌"
            fi
        done
    else
        echo -n "Checking {{template}}... "
        if [[ "{{seeded}}" == "true" ]]; then
            chezmoi execute-template {{seed-base}} < "{{template}}" >/dev/null 2>&1 && echo "✅" || echo "❌"
        else
            chezmoi execute-template < "{{template}}" >/dev/null 2>&1 && echo "✅" || echo "❌"
        fi
    fi

# Save template outputs to files for inspection
save seeded="false":
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{seeded}}" == "true" ]]; then
        echo "💾 Saving seeded template outputs to test-output/seeded/"
        mkdir -p test-output/seeded
        for template in {{templates}}; do
            base_name=$(basename "$template" .tmpl)
            chezmoi execute-template {{seed-base}} < "$template" > "test-output/seeded/${base_name}.test"
        done
        chezmoi execute-template {{seed-linux}} < "run_onchange_00-install-packages.sh.tmpl" > "test-output/seeded/run_onchange_00-install-packages-linux.test"
        chezmoi execute-template {{seed-work}} < "dot_zshrc.tmpl" > "test-output/seeded/dot_zshrc-work.test"
        echo "✅ Outputs saved to test-output/seeded/"
    else
        echo "💾 Saving template outputs to test-output/"
        mkdir -p test-output
        for template in {{templates}}; do
            base_name=$(basename "$template" .tmpl)
            chezmoi execute-template < "$template" > "test-output/${base_name}.test"
        done
        echo "✅ Outputs saved to test-output/"
    fi

# List all template files in the repository
list-templates:
    @echo "📄 Template files found in repository:"
    @find . -name "*.tmpl" -type f | sed 's|^\./||' | sort

# Show chezmoi template data for debugging
show-data:
    @echo "📊 Available chezmoi template data:"
    @chezmoi data

# Clean up test output files
clean:
    @echo "🧹 Cleaning up test output files..."
    @rm -rf test-output/
    @echo "✅ Cleanup completed"

# Show available recipes and usage examples
help:
    @echo "🔧 Available justfile recipes:"
    @echo ""
    @echo "Main testing commands:"
    @echo "  just test                    - Test all templates (silent)"
    @echo "  just test verbose=true       - Test all with output"
    @echo "  just test seeded=true        - Test all with seed data"
    @echo "  just test verbose=true seeded=true - Test with both"
    @echo ""
    @echo "Individual template testing:"
    @echo "  just test-one FILE           - Test specific template"
    @echo "  just test-one FILE verbose=true - Test with output"
    @echo "  just test-one FILE seeded=true - Test with seed data"
    @echo "  just test-one FILE scenario=work - Test with work machine data"
    @echo "  just test-one FILE scenario=linux - Test with Linux/Bazzite data"
    @echo ""
    @echo "Quick operations:"
    @echo "  just check                   - Quick syntax check for all"
    @echo "  just check FILE              - Quick syntax check for specific template"
    @echo "  just check seeded=true       - Quick check with seed data"
    @echo ""
    @echo "Output management:"
    @echo "  just save                    - Save template outputs to files"
    @echo "  just save seeded=true        - Save seeded outputs to files"
    @echo "  just clean                   - Clean up test output files"
    @echo ""
    @echo "Utility commands:"
    @echo "  just list-templates          - List all template files"
    @echo "  just show-data               - Show available chezmoi template data"
    @echo "  just help                    - Show this help message"
    @echo ""
    @echo "Examples:"
    @echo "  just test seeded=true verbose=true"
    @echo "  just test-one dot_zshrc.tmpl scenario=work verbose=true"
    @echo "  just check run_onchange_00-install-packages.sh.tmpl seeded=true"
