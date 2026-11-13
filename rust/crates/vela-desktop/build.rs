fn main() {
    #[cfg(windows)]
    {
        let mut resources = winresource::WindowsResource::new();
        resources.set_icon("../../packaging/vela.ico");
        resources.set("ProductName", "Vela");
        resources.set("FileDescription", "Vela desktop IPTV player");
        resources.set("ProductVersion", env!("CARGO_PKG_VERSION"));
        resources
            .compile()
            .expect("compile Windows application resources");
    }
}
