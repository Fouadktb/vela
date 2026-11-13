use super::Section;
use std::collections::BTreeMap;
use vela_core::{CatalogItem, CatalogQuery};

#[derive(Clone, Default)]
pub(super) struct BrowsingState {
    pub query: CatalogQuery,
    pub category_search: String,
    pub selection: Option<CatalogItem>,
}

#[derive(Default)]
pub(super) struct BrowsingMemory(BTreeMap<Section, BrowsingState>);
impl BrowsingMemory {
    pub fn switch(&mut self, from: Section, to: Section, state: BrowsingState) -> BrowsingState {
        self.0.insert(from, state);
        self.0.get(&to).cloned().unwrap_or_else(|| BrowsingState {
            query: CatalogQuery {
                content_type: to.kind(),
                favorites_only: to == Section::Favorites,
                limit: super::PAGE_SIZE,
                ..Default::default()
            },
            ..Default::default()
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn switching_sections_preserves_independent_filters_pages_and_scoped_selection() {
        let mut memory = BrowsingMemory::default();
        let movies = BrowsingState {
            query: CatalogQuery {
                search: "/ film".into(),
                category_id: Some("films".into()),
                provider_id: Some("provider-a".into()),
                offset: 60,
                limit: 60,
                content_type: Some("movie".into()),
                ..Default::default()
            },
            category_search: "favorites".into(),
            selection: Some(CatalogItem {
                id: "shared".into(),
                provider_id: "provider-a".into(),
                content_type: "movie".into(),
                ..Default::default()
            }),
        };
        let mut favorites = memory.switch(Section::Movies, Section::Favorites, movies);
        assert!(favorites.query.favorites_only);
        assert!(favorites.query.search.is_empty());
        favorites.query.search = "my saved films".into();
        favorites.selection = Some(CatalogItem {
            id: "shared".into(),
            provider_id: "provider-b".into(),
            content_type: "series".into(),
            ..Default::default()
        });
        let restored = memory.switch(Section::Favorites, Section::Movies, favorites);
        assert_eq!(restored.query.search, "/ film");
        assert_eq!(restored.query.offset, 60);
        assert_eq!(restored.query.category_id.as_deref(), Some("films"));
        assert_eq!(restored.category_search, "favorites");
        assert_eq!(
            restored.selection.as_ref().unwrap().provider_id,
            "provider-a"
        );
        let favorites = memory.switch(Section::Movies, Section::Favorites, restored);
        assert_eq!(favorites.query.search, "my saved films");
        assert_eq!(
            favorites.selection.as_ref().unwrap().provider_id,
            "provider-b"
        );
        let recent = memory.switch(Section::Favorites, Section::Recent, favorites);
        assert!(!recent.query.favorites_only);
        assert!(recent.query.content_type.is_none());
    }
}
