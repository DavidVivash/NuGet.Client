﻿using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using NuGet.Configuration;
using NuGet.Protocol.Core.Types;

namespace NuGet.Protocol
{
    public class HttpSourceResourceProvider : ResourceProvider
    {
        // Only one HttpSource per source should exist. This is to reduce the number of TCP connections.
        private readonly ConcurrentDictionary<PackageSource, HttpSourceResource> _cache
            = new ConcurrentDictionary<PackageSource, HttpSourceResource>();

        public HttpSourceResourceProvider()
            : base(typeof(HttpSourceResource),
                  nameof(HttpSourceResource),
                  NuGetResourceProviderPositions.Last)
        {
        }

        public override Task<Tuple<bool, INuGetResource>> TryCreate(SourceRepository source, CancellationToken token)
        {
            Debug.Assert(source.PackageSource.IsHttp, "HTTP source requested for a non-http source.");

            HttpSourceResource curResource = null;

            if (source.PackageSource.IsHttp)
            {
                curResource = _cache.GetOrAdd(source.PackageSource, 
                    (packageSource) => new HttpSourceResource(HttpSource.Create(source)));
            }

            return Task.FromResult(new Tuple<bool, INuGetResource>(curResource != null, curResource));
        }
    }
}
