; extends

; const query = /* GraphQL */ `...`
((comment) @_gql_comment
  .
  (template_string) @injection.content
  (#eq? @_gql_comment "/* GraphQL */")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children)
  (#set! injection.language "graphql"))
