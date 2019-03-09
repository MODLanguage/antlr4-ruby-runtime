require '../antlr4/uuid'

u1 = UUID.from_string('59627784-3BE5-417A-B9EB-8131A7286089')
u2 = UUID.from_string('59627784-3BE5-417A-B9EB-8131A7286089')
puts u1 == u2