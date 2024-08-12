import axios from 'axios';
import { useQuery } from '@tanstack/react-query';
import { useApi } from '../context/ApiContext';

const Discover = () => {
  const url = useApi();
  
  const getTest = async () => {
      const res = await axios.get(`${url.api_url}/api/test`);
      return res.data;
  }

  const { isLoading, error, data } = useQuery({ 
    queryKey: ['todos'], 
    queryFn: getTest 
  })

  if (isLoading) return <div>Loading...</div>;

  if (error) return <div>Error: {error.message}</div>;

  console.log(data);
  return (
    <section className='page-discover'>
        <div className='page-discover-content'>
            <div className='page-discover-content-video'>
                {/* <iframe className="page-discover-content-video-player" width="560" height="315" src="https://www.youtube.com/embed/MgTsvp2Sclc?si=BjozaLG59dcq5_xH" title="YouTube video player" frameBorder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe> */}
            </div>
        </div>
        <div className='page-discover-container'>
            <div className='page-discover-container-content'>
              <div className='page-discover-container-content-title'>
                <span>Découvrir Anonym</span>
                <h1>TROUVEZ VOTRE COMMUNAUTE SUR ANONYM</h1>
              </div>
            </div>
        </div>
    </section>
  );
};

export default Discover;