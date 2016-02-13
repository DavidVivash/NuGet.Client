﻿using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using NuGet.Frameworks;
using NuGet.Logging;
using NuGet.Packaging.Core;
using NuGet.Protocol.Core.Types;
using NuGet.Versioning;
using Test.Utility;
using Xunit;

namespace NuGet.Protocol.Core.v3.Tests
{
    public class DependencyInfoResourceV2FeedTests
    {
        [Fact]
        public async Task DependencyInfoResourceV2Feed_GetDependencyInfoById()
        {
            Func<Task<HttpHandlerResource>> factory = () =>
                Task.FromResult<HttpHandlerResource>(new TestHttpHandler(new TestHandler()));

            var httpSource = new HttpSource(
                new Configuration.PackageSource("http://testsource/v2/"),
                factory);

            V2FeedParser parser = new V2FeedParser(httpSource, "http://testsource/v2/");

            var dependencyInfoResource = new DependencyInfoResourceV2Feed(parser, null);

            var dependencyInfoList = await dependencyInfoResource.ResolvePackages("WindowsAzure.Storage", 
                                                                            NuGetFramework.Parse("aspnetcore50"),
                                                                            NullLogger.Instance, 
                                                                            CancellationToken.None);

            Assert.Equal(34, dependencyInfoList.Count());
        }

        [Fact]
        public async Task DependencyInfoResourceV2Feed_GetDependencyInfoByPackageIdentity()
        {
            Func<Task<HttpHandlerResource>> factory = () =>
                Task.FromResult<HttpHandlerResource>(new TestHttpHandler(new TestHandler()));

            var httpSource = new HttpSource(
                new Configuration.PackageSource("http://testsource/v2/"),
                factory);

            V2FeedParser parser = new V2FeedParser(httpSource, "http://testsource/v2/");

            var dependencyInfoResource = new DependencyInfoResourceV2Feed(parser, null);

            var packageIdentity = new PackageIdentity("WindowsAzure.Storage", new NuGetVersion("4.3.2-preview"));

            var dependencyInfo = await dependencyInfoResource.ResolvePackage(packageIdentity,
                                                                            NuGetFramework.Parse("aspnetcore50"),
                                                                            NullLogger.Instance,
                                                                            CancellationToken.None);

            Assert.Equal(43, dependencyInfo.Dependencies.Count());
        }

        [Fact]
        public async Task DependencyInfo_XunitRetrieveExactVersion()
        {
            // Arrange
            var repo = Repository.Factory.GetCoreV3("https://www.nuget.org/api/v2/");
            var resource = await repo.GetResourceAsync<DependencyInfoResource>();

            var package = new PackageIdentity("xunit", NuGetVersion.Parse("2.1.0-beta1-build2945"));
            var dep1 = new PackageIdentity("xunit.core", NuGetVersion.Parse("2.1.0-beta1-build2945"));
            var dep2 = new PackageIdentity("xunit.assert", NuGetVersion.Parse("2.1.0-beta1-build2945"));

            // Act
            var result = await resource.ResolvePackage(package, NuGetFramework.Parse("net45"), Logging.NullLogger.Instance, CancellationToken.None);

            // Assert
            Assert.Equal(package, result, PackageIdentity.Comparer);
            Assert.Equal(2, result.Dependencies.Count());
            Assert.Equal("[2.1.0-beta1-build2945, 2.1.0-beta1-build2945]", result.Dependencies.Single(dep => dep.Id == "xunit.core").VersionRange.ToNormalizedString());
            Assert.Equal("[2.1.0-beta1-build2945, 2.1.0-beta1-build2945]", result.Dependencies.Single(dep => dep.Id == "xunit.assert").VersionRange.ToNormalizedString());
        }

        [Fact]
        public async Task DependencyInfo_XunitRetrieveDependencies()
        {
            // Arrange
            var repo = Repository.Factory.GetCoreV3("https://www.nuget.org/api/v2/");
            var resource = await repo.GetResourceAsync<DependencyInfoResource>();

            var package = new PackageIdentity("xunit", NuGetVersion.Parse("2.1.0-beta1-build2945"));

            // filter to keep this test consistent
            var filterRange = new VersionRange(NuGetVersion.Parse("2.0.0-rc4-build2924"), true, NuGetVersion.Parse("2.1.0-beta1-build2945"), true);

            // Act
            var results = await resource.ResolvePackages("xunit", NuGetFramework.Parse("net45"), Logging.NullLogger.Instance, CancellationToken.None);

            var filtered = results.Where(result => filterRange.Satisfies(result.Version));

            var target = filtered.Single(p => PackageIdentity.Comparer.Equals(p, package));

            // Assert
            Assert.Equal(3, filtered.Count());
            Assert.Equal(2, target.Dependencies.Count());
            Assert.Equal("[2.1.0-beta1-build2945, 2.1.0-beta1-build2945]", target.Dependencies.Single(dep => dep.Id == "xunit.core").VersionRange.ToNormalizedString());
            Assert.Equal("[2.1.0-beta1-build2945, 2.1.0-beta1-build2945]", target.Dependencies.Single(dep => dep.Id == "xunit.assert").VersionRange.ToNormalizedString());
        }

        [Fact]
        public async Task DependencyInfo_XunitRetrieveExactVersion_NotFound()
        {
            // Arrange
            var repo = Repository.Factory.GetCoreV3("https://www.nuget.org/api/v2/");
            var resource = await repo.GetResourceAsync<DependencyInfoResource>();

            var package = new PackageIdentity("nuget.core", NuGetVersion.Parse("1.0.0-notfound"));

            // Act
            var result = await resource.ResolvePackage(package, NuGetFramework.Parse("net45"), Logging.NullLogger.Instance, CancellationToken.None);

            // Assert
            Assert.Null(result);
        }

        [Fact]
        public async Task DependencyInfo_XunitRetrieveDependencies_NotFound()
        {
            // Arrange
            var repo = Repository.Factory.GetCoreV3("https://www.nuget.org/api/v2/");
            var resource = await repo.GetResourceAsync<DependencyInfoResource>();

            var package = new PackageIdentity("nuget.notfound", NuGetVersion.Parse("1.0.0-blah"));

            // Act
            var results = await resource.ResolvePackages("nuget.notfound", NuGetFramework.Parse("net45"), Logging.NullLogger.Instance, CancellationToken.None);

            // Assert
            Assert.Equal(0, results.Count());
        }
    }
}
