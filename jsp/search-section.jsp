<section class="section">
    <div class="container">
     
        <h2 class="title">Let Search!</h2>
        <h3 class="subtitle">
          You can also select <strong>the ranking method</strong> for your searching.
        </h3>

        <form name="search" action="results.jsp" method="get">
            <p class="control has-addons">
                <input class="input is-info is-large" type="text" placeholder="Type input here" name="query" size="44"/>
                <input class="button is-info is-large" type="submit" value="Search">
                <span class="select is-info is-large">
                    <select name="search_method">
                        <option value="Similarity" selected="selected">Similarity</option>
                        <option value="PageRank">PageRank</option>
                        <option value="MixScore">ReRank</option>
                    </select>
                </span>
            </p>
            <p>
                <input lass="is-info" name="alpha" size="4" value="0.5"/>&nbsp;<span class="subtitle">alpha</span>
                <input lass="is-info" name="beta" size="4" value="0.5"/>&nbsp;<span class="subtitle">beta</span>
                <input lass="is-info" name="maxresults" size="4" value="10"/>&nbsp;<span class="subtitle">Results Per Page</span>
            </p>
            <h6 class="subtitle">
              Note : alpha and beta only work when search with MixScore method. And the sum of them must equal 1.
            </h6>
        </form>
    </div>
</section>